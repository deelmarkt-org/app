# PR #159 — P-44 Social Login: Tier-1 Production Audit & Implementation Plan

**Auditor:** Senior Staff Engineer (architectural authority)
**Date:** 2026-04-15
**PR:** [#159 `feat(auth): P-44 — Social Login (Google + Apple)`](https://github.com/deelmarkt-org/app/pull/159)
**Base → Head:** `dev` ← `feature/pizmam-P44-social-login` · +902 / −116 · 20 files
**Companion branch:** `feature/reso-P44-oauth-user-trigger` (trigger + config.toml, not yet PR'd)
**Spec:** [docs/screens/01-auth/05-social-login.md](../screens/01-auth/05-social-login.md)
**Sprint:** [SPRINT-PLAN.md §P-44](../SPRINT-PLAN.md)

---

## 1. Verdict

**🟡 Conditional approve — merge blocked until P0 gaps closed.**

The Flutter domain/presentation slice is well-architected: Clean Architecture respected, sealed `AuthResult` extended with exhaustive OAuth subtypes, Riverpod `@riverpod` notifier with per-provider loading, error mapping extracted to a mixin. Tests are thorough for the code that exists.

However, this PR **does not ship working social login.** It ships a Flutter client that calls `supabase.auth.signInWithOAuth(...)` with zero native platform wiring, no provider configuration, no redirect handling, no PKCE verification path, no deep-link intent filters, and no integration with reso's trigger branch. Shipping to `dev` is fine; shipping to `main` as-is would be a broken feature behind a button.

SonarCloud gate is **failing**: 79.5% coverage on new code vs 80% required.

---

## 2. Scope vs Spec Compliance Matrix

| Spec requirement | PR #159 status | Gap |
|---|---|---|
| Route `/auth/social` dedicated screen | ❌ Not implemented — inline buttons only on `LoginScreen` | Either update spec or create `SocialLoginScreen` |
| Heading `"Inloggen met"` | ❌ Missing | l10n keys not added |
| Google button — white bg, "G" logo, "Doorgaan met Google" | 🟡 Uses `DeelButton outline` + Phosphor duotone, not spec copy | Visual drift from design PNG |
| Apple button — black bg, Apple logo, "Doorgaan met Apple" | 🟡 Same outline variant, not black-filled per HIG | Violates Apple HIG for Sign in with Apple (rejection risk) |
| "of" / "or" divider | ❌ Missing | Spec §Layout 4 |
| Email fallback link | ❌ Missing | Spec §Layout 5 |
| Terms footer with links | ❌ Missing | Spec §Layout 6 — legal-adjacent, consent trail implication |
| L10n keys (`auth.signInWith`, `auth.continueGoogle`, `auth.continueApple`, `auth.or`, `auth.signInEmail`, `auth.agreeTerms`, `auth.terms`, `auth.privacy`) | ❌ Only `continueWithGoogle`/`continueWithApple` present, and with different keys (`continueWith*` vs spec `continue*`) | 7 of 8 spec keys missing; existing key names differ from spec |
| Accessibility: 52px height, focus ring, screen-reader labels | 🟡 `Semantics(button:true, label:…)` wrapper added; height follows `DeelButton` default | Verify ≥44px target in widget test |
| Light + dark + mobile + desktop variants from designs | ❌ No `SCREEN-MAP.md` link from `login_screen.dart` to spec; no dedicated screen to parity-check | Reference comment present on `LoginSocialButtons`, not enough |

**Verdict on scope:** The PR implements the **plumbing** but not the **screen**. The `05-social-login.md` spec describes a dedicated full-screen route; the PR opts for embedded buttons on `LoginScreen`. This is a defensible product decision, **but the spec was not updated to reflect it.** Per CLAUDE.md §7.1 Pre-Implementation Verification, this divergence should have been flagged and resolved before coding.

---

## 3. Architecture & Code Review (§1 Clean Architecture)

### What's right
- ✅ `OAuthProvider` enum in domain (no `supabase_flutter` leak) — exemplary.
- ✅ `AuthFailureOAuthCancelled` / `AuthFailureOAuthUnavailable` added to sealed `AuthResult` — exhaustive `switch` preserved at call sites.
- ✅ `AuthErrorMapper` extracted to mixin — keeps `AuthRepositoryImpl` under §2.1's 200-line cap.
- ✅ `SocialLoginNotifier` (≈40 lines) uses `@riverpod` codegen; independent `loadingProvider` per button is a real UX win.
- ✅ `_handleAuthResult` / `_buildContent` split keeps `LoginScreen.build()` under SonarCloud's 60-line method threshold.

### Findings

**F-01 [HIGH] — Login without PKCE / server-side flow**
`supabase.auth.signInWithOAuth(..., authScreenLaunchMode: LaunchMode.inAppBrowserView)` on mobile uses the implicit-flow redirect. For iOS Apple Sign-In, Supabase strongly recommends using `signInWithIdToken(provider: apple, idToken, nonce)` via `sign_in_with_apple` package for native flow (no web sheet, no rejection risk in App Review §5.1.1). Same for Google on Android (native `google_sign_in`). Current implementation will work but:
- Apple will reject App Store submissions that route Sign in with Apple through a WebView (HIG §Sign in with Apple).
- Google one-tap / native consent is degraded UX.
- No nonce → ID-token replay risk.

**F-02 [HIGH] — `currentUser` race after OAuth completes**
```dart
final completed = await _datasource.signInWithGoogle();
if (!completed) return const AuthFailureOAuthCancelled();
final userId = _datasource.currentUser?.id;
if (userId == null) return const AuthFailureOAuthCancelled();  // ⚠ conflates null with cancel
```
`signInWithOAuth` returns `true` when the URL is launched successfully — **not when the session is established.** On mobile, control returns to the app via a deep-link callback *later*. Reading `currentUser` immediately after returns stale null → false "cancelled" classification. Must listen to `onAuthStateChange` for `AuthChangeEvent.signedIn`.

**F-03 [MEDIUM] — No deep-link / redirect URL wiring**
- Android: `AndroidManifest.xml` has no `intent-filter` for the Supabase callback URL (e.g. `io.supabase.deelmarkt://login-callback`).
- iOS: `Info.plist` has one `CFBundleURLScheme` (`deelmarkt`) — not aligned with Supabase's documented callback scheme; no `applinks` for universal links.
- `supabase/config.toml` `[auth.external.apple]` is `enabled = false`, `[auth.external.google]` section does not exist. reso's branch adds them but is still unmerged.

**F-04 [MEDIUM] — Missing packages**
`pubspec.yaml` has `supabase_flutter: ^2.8.0` but no `sign_in_with_apple`, no `google_sign_in`. Required for F-01 remediation.

**F-05 [LOW] — Error mapper: string-match on `"provider"` + `"disabled"`**
Fragile — Supabase may change wording. Prefer matching Supabase's `AuthApiException.code == 'provider_disabled'` (2.8.x exposes error codes) or HTTP 422 with specific body.

**F-06 [LOW] — `SocialLoginState.copyWith` is broken**
```dart
SocialLoginState copyWith({OAuthProvider? loadingProvider, AuthResult? result}) {
  return SocialLoginState(loadingProvider: loadingProvider, result: result);
}
```
Not a true `copyWith` — always discards the existing field when the parameter is null. Currently unused (notifier always builds fresh state), but this is a footgun. Remove it or fix with sentinel-wrapped nullable (`ValueGetter` pattern).

**F-07 [LOW] — `LoginScreen._handleAuthResult` includes unreachable OAuth cases**
`loginViewModelProvider` never emits OAuth results (confirmed by comment and tests). The two no-op cases exist only to satisfy the exhaustive `switch`. Acceptable, but a narrower `sealed` hierarchy (e.g. `EmailAuthResult` vs `OAuthResult` extending `AuthResult`) would eliminate dead branches.

**F-08 [INFO] — `LoginSocialButtons` l10n drift**
Widget uses `auth.continueWithGoogle` / `auth.continueWithApple` (existing pre-P-44 keys). Spec mandates `auth.continueGoogle` / `auth.continueApple`. Choose one set and delete the other — keeping both invites divergence.

**F-09 [INFO] — Out-of-scope changes in P-44 PR**
`appeal_screen.dart`, `suspension_gate_status.dart`, `settings_screen_test.dart` modifications belong to P-53 / unrelated work. They are small and correct, but pollute the feature blast-radius. Per §5 Git Workflow, a feature branch should contain one feature.

---

## 4. Quality Gates (§8, quality-gate.md principles)

| Gate | Required | Actual | Status |
|---|---|---|---|
| `flutter analyze` | 0 warn | pass (CI) | ✅ |
| `dart format` | pass | pass | ✅ |
| Unit + widget tests | all green, 3352 ✓ | pass | ✅ |
| Coverage on new code (§6 / §8) | ≥ 80 % | **79.5 %** | ❌ **blocking** |
| `check_quality.dart` | 0 violations | pass | ✅ |
| Edge Function structure | n/a | n/a | — |
| `check_deployments.sh` | 0 pending | **pending migration on reso branch** | ❌ |
| Security: no secrets in code | pass | pass | ✅ |
| RLS impact | n/a (auth schema) | reso trigger is `SECURITY DEFINER` + search_path set | ✅ |
| Accessibility: ≥44×44 targets, Semantics labels, contrast | Semantics added | **no widget test asserts touch-target size** | 🟡 |
| L10n keys NL + EN | all present | 1 new pair added; 7 spec-mandated keys missing | 🟡 |
| CLAUDE.md §2.1 file sizes | all under limits | max 140 lines (`login_social_buttons_test.dart` = 134) | ✅ |
| CLAUDE.md §7.1 pre-impl verification | produced in PR description | **not produced** | ❌ |

---

## 5. Security Review

- ✅ No hardcoded secrets.
- ✅ No PII/token logging in error branches.
- ⚠ **OAuth redirect URL not validated against an allowlist** — `authScreenLaunchMode: inAppBrowserView` hands control to Supabase's default redirect; Android and iOS must register and verify the callback scheme to prevent hijacking by a malicious app claiming the same intent filter.
- ⚠ **No nonce / PKCE for Apple ID token** (see F-01). Apple requires nonce to prevent replay.
- ✅ `AuthRemoteDatasource` does not log OAuth parameters.
- ✅ reso trigger uses `SECURITY DEFINER` with `SET search_path = public` — correct hardening; `ON CONFLICT DO NOTHING` prevents metadata overwrite.
- ⚠ Trigger pulls `raw_user_meta_data->>'avatar_url'` / `'picture'` with `TRIM` but **does not validate URL scheme** (http/https) or length. Malicious provider metadata could store `javascript:` URLs. Add a `CHECK` on `user_profiles.avatar_url` or validate in the trigger.

---

## 6. Missing / Gaps Summary (actionable)

Classified by severity:

### P0 — must ship before merging to main
1. **Coverage** — lift new-code coverage ≥ 80 % (add tests for `LoginScreen._buildContent` expanded-breakpoint branch, `mapLoginGenericError` unknown branch, and the `copyWith` or remove it).
2. **Native OAuth flow** — add `sign_in_with_apple` + `google_sign_in` packages; route Apple via `signInWithIdToken` with nonce; keep `signInWithOAuth` as the web fallback.
3. **Auth state listener** — replace `currentUser` immediate-read with `onAuthStateChange` subscription; resolve `Future<AuthResult>` when `signedIn` event arrives, or time out after 60 s → `AuthFailureOAuthCancelled`.
4. **Deep-link / intent-filter wiring** — Android `intent-filter` for `io.supabase.deelmarkt://login-callback`; iOS `CFBundleURLTypes` entry; update `config.toml` additional_redirect_urls list.
5. **Merge reso branch first** — the trigger must be applied before OAuth accounts exist, otherwise new sign-ins land with no `user_profiles` row and RLS-guarded queries fail.
6. **Supabase provider enable** — `[auth.external.google]` section to config.toml, `enabled = true` for both, secrets via env substitution, client IDs from Google Cloud + Apple Developer.

### P1 — before feature reaches users
7. **Screen parity** — decide: dedicated `/auth/social` route (honour spec) **or** update `05-social-login.md` to document "embedded on login" pattern. Add missing l10n keys (divider, email fallback link, terms footer).
8. **Apple button visual** — filled black variant per HIG, not outline.
9. **Error mapper hardening** — use Supabase error codes, not substring match.
10. **`copyWith` fix or removal.**
11. **Avatar URL validation** in trigger (scheme allowlist, length cap).
12. **E2E** — Playwright/integration test for the golden path (tap Google → consent → `/home`) on web target; mocked flows on mobile.

### P2 — hygiene
13. Split `appeal_screen` / `suspension_gate_status` changes into their own PR.
14. Consider narrower `sealed` hierarchy (`EmailAuthResult` / `OAuthResult`) to remove dead `switch` cases.
15. Rename `continueWithGoogle` → `continueGoogle` to match spec, migrate references, delete `socialLoginComingSoon` key now that it's unused.

---

## 7. Implementation Plan (follow-on PRs)

Per `.agent/workflows/plan.md` methodology: restate → risks → phased tasks → verification.

### 7.0 Restated objective

Ship **working** Google + Apple Sign-In for DeelMarkt across iOS, Android, and Web, aligned with platform guidelines (Apple HIG §Sign in with Apple, Google Material), with zero regression to existing email auth, full `user_profiles` auto-provisioning, and ≥80 % coverage.

### 7.1 Risk register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Apple App Review rejection for WebView Sign in with Apple | High | Blocks launch | Use `sign_in_with_apple` native sheet on iOS |
| Deep-link hijack on Android (custom scheme) | Medium | Credential theft | App Links with `android:autoVerify="true"` + SHA-256 fingerprint in assetlinks.json |
| Race on `currentUser` before session settles | High | Users see "cancelled" after successful sign-in | Subscribe to `onAuthStateChange`; add 60 s timeout |
| Missing `user_profiles` row for OAuth users | High | RLS-protected queries fail on first launch | Apply reso's trigger migration **before** enabling providers |
| Apple hides email with `@privaterelay.appleid.com` | Medium | Breaks email-based lookups (seller contact, receipts) | Treat email as opaque account ID; display name only; document in `user_profiles` |
| Secret leakage via client ID in binary | Low | Public IDs only — acceptable | Store client secrets in Supabase Vault, never in Flutter |

### 7.2 Workstreams

#### WS-A — Backend (reso) `[R]`
**Branch:** continue on `feature/reso-P44-oauth-user-trigger`, open PR targeting `dev`.

| # | Task | File(s) | Acceptance |
|---|---|---|---|
| A-1 | Merge existing migration (verify `ON CONFLICT DO NOTHING` + SECURITY DEFINER) | `supabase/migrations/20260415120000_p44_oauth_user_profile_trigger.sql` | Applied via `check_deployments.sh --deploy` on staging |
| A-2 | Harden trigger: validate avatar URL scheme (`^https?://`), length ≤ 500 | same migration or follow-up | Unit test with malicious `javascript:` meta returns null avatar |
| A-3 | Add `[auth.external.google]` block to `config.toml`; enable both providers; wire `SUPABASE_AUTH_EXTERNAL_{APPLE,GOOGLE}_{SECRET,CLIENT_ID}` env substitution | `supabase/config.toml` | Local `supabase start` shows providers enabled |
| A-4 | Upload Google OAuth credentials (Web + iOS + Android client IDs) and Apple Sign-In key to **Supabase Dashboard → Auth → Providers** (not via config.toml in CI) | manual | Verified by Staff Eng |
| A-5 | Add `additional_redirect_urls` to config: `io.supabase.deelmarkt://login-callback`, `https://deelmarkt.com/auth/callback` | `config.toml` | `supabase db diff` clean |
| A-6 | Document run-book: how to rotate OAuth secrets | `docs/operations/oauth-runbook.md` | New doc exists, peer-reviewed |

#### WS-B — Platform wiring (belengaz) `[B]`
**Branch:** `feature/belengaz-P44-oauth-platform-wiring`, base `dev`.

| # | Task | File(s) | Acceptance |
|---|---|---|---|
| B-1 | Android: add `intent-filter` for `io.supabase.deelmarkt://login-callback` to `MainActivity` | `android/app/src/main/AndroidManifest.xml` | Deep link resolves to app |
| B-2 | Android App Links: add assetlinks.json fingerprint for `deelmarkt.com/auth/callback` | served by Cloudflare | `adb shell pm verify-app-links --re-verify` passes |
| B-3 | iOS: add `CFBundleURLTypes` entry with scheme `io.supabase.deelmarkt` | `ios/Runner/Info.plist` | Universal link opens app |
| B-4 | iOS: enable **Sign In with Apple** capability in `Runner.entitlements`; add associated domain `applinks:deelmarkt.com` | `ios/Runner/Runner.entitlements` | Xcode build green |
| B-5 | Web: verify `web/index.html` meta + hash routing OK for OAuth return | `web/index.html` | Web golden path passes |
| B-6 | CI: add a build matrix check that fails if entitlements / manifest drift | `.github/workflows/build-check.yml` | Hook fires on manifest change |

#### WS-C — Flutter core + screen parity (pizmam) `[P]`
**Branch:** `feature/pizmam-P44-oauth-native-flow`, base `dev`.

| # | Task | File(s) | Acceptance |
|---|---|---|---|
| C-1 | Add dependencies: `sign_in_with_apple: ^6.1.0`, `google_sign_in: ^6.2.0`, `crypto` (for nonce) | `pubspec.yaml` | `flutter pub get` clean |
| C-2 | Refactor `AuthRemoteDatasource.signInWithApple()` to use native sheet + `signInWithIdToken(provider: apple, idToken, accessToken, nonce)` on iOS; fall back to `signInWithOAuth` on Android/Web | `auth_remote_datasource.dart` | Unit + integration tests |
| C-3 | Same for Google: `GoogleSignIn().signIn()` → `signInWithIdToken(provider: google, idToken, accessToken)` on mobile; web keeps `signInWithOAuth` | same | same |
| C-4 | Replace `currentUser` immediate read with subscription to `onAuthStateChange` → completes `Completer<AuthResult>`; 60 s timeout → `AuthFailureOAuthCancelled` | `auth_repository_impl.dart` | Unit tests with fake auth stream |
| C-5 | Fix `SocialLoginState.copyWith` or remove it (choose: remove since unused) | `social_login_viewmodel.dart` | Coverage unaffected |
| C-6 | Harden `mapOAuthAuthError` to match Supabase error codes (not substring) | `auth_error_mapper.dart` | Tests updated |
| C-7 | Add missing l10n keys from spec §L10n Keys (`signInWith`, `or`, `signInEmail`, `agreeTerms`, `terms`, `privacy`) to both `en-US.json` and `nl-NL.json`; deprecate `socialLoginComingSoon` | `assets/l10n/*.json` | All l10n referenced by code |
| C-8 | Decision point — option A: build dedicated `SocialLoginScreen` at `/auth/social` following [`05-social-login.md`](../screens/01-auth/05-social-login.md) and [`01-auth/designs/social_login_*`](../screens/01-auth/designs/); option B: update spec to document embedded pattern | `lib/features/auth/presentation/screens/social_login_screen.dart` **or** `docs/screens/01-auth/05-social-login.md` | Spec and code agree |
| C-9 | If option A: add `GoRoute('/auth/social')` to `app_router.dart` with `CustomTransitionPage` | `lib/core/router/app_router.dart` | Route covered by router test |
| C-10 | Apple button: filled black variant (`DeelButtonVariant.primaryDark` or new `apple` variant) to comply with HIG | `login_social_buttons.dart` | Visual matches `social_login_mobile_light/screen.png` |
| C-11 | Widget test: assert ≥44×44 touch target on both buttons using `a11y_touch_target_utils` | `login_social_buttons_test.dart` | A11y test green |
| C-12 | Widget test: assert `signInWith` heading + divider + email fallback + terms footer render (if option A) | new `social_login_screen_test.dart` | Coverage ≥80 % on new code |
| C-13 | Split unrelated `appeal_screen` / `suspension_gate_status` changes from this PR into `chore/p53-followups` | n/a | PR #159 diff focused on P-44 |

#### WS-D — E2E & release hardening (shared)
| # | Task | Owner | Acceptance |
|---|---|---|---|
| D-1 | Playwright web test: tap Google → stub OAuth redirect → lands on `/home` | `[P]` | CI green |
| D-2 | Integration test (Flutter `integration_test`): mobile mocked Google + Apple flows | `[P]` | `flutter test integration_test` green |
| D-3 | Manual test matrix: iOS 17/18 physical device, Android 13/14 device, Chrome + Safari web, both NL + EN locales | `[P]` + `[B]` | Matrix checklist in PR body |
| D-4 | Add OAuth events to privacy policy disclosure | legal | Policy updated |
| D-5 | Update `docs/epics/E02-user-auth-kyc.md` with OAuth acceptance criteria (currently missing per SPRINT-PLAN.md note) | `[P]` | Epic audit in PR checklist |

### 7.3 Dependency graph & merge order
```
 WS-A (reso trigger + config) ──┐
                                ├──► WS-C (Flutter native flow + screen)
 WS-B (platform wiring) ────────┘                │
                                                 ├──► WS-D (E2E + release)
                                                 └──► enable in staging
```
**Merge order:** A → B (parallel OK with A) → C → D. Providers must not be `enabled=true` in config until A-1 migration is applied, else first real OAuth sign-in creates orphaned `auth.users` row.

### 7.4 Estimated effort
- WS-A: 0.5 day (migration exists; mostly config + runbook)
- WS-B: 1 day (manifest + entitlements + Cloudflare assetlinks)
- WS-C: 2 days (native flow + state listener + spec alignment + a11y tests)
- WS-D: 1 day (E2E + manual matrix + docs)

**Total: ~4.5 dev-days** across three developers.

### 7.5 Done-definition
- [ ] All P0 items in §6 closed
- [ ] Coverage on new code ≥ 80 % (SonarCloud green)
- [ ] Manual matrix (§D-3) passed with screenshots in PR
- [ ] `check_deployments.sh` exit 0
- [ ] Apple App Review Guideline §5.1.1 compliance confirmed (native sheet, not WebView)
- [ ] Epic E02 updated with OAuth acceptance criteria
- [ ] Spec `05-social-login.md` and implementation agree on route/layout
- [ ] reso's migration PR merged to `dev`
- [ ] Sign-off from Senior Staff Engineer

---

## 8. Recommendation for this PR (#159)

**Disposition:** **Merge to `dev`** after two quick fixes — **do not promote to `main`** until WS-A/B/C/D land.

Immediate quick fixes before merging to `dev`:
1. Lift coverage to ≥ 80 % (add 2-3 tests — see C-11 / remove unused `copyWith`).
2. Split the `appeal_screen` / `suspension_gate_status` / `settings_screen_test` diffs into a separate PR (§F-09).

Track remaining work as follow-on PRs per §7.2.
