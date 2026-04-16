# PLAN — P-43 App Store Screenshots + ASO Metadata

> **Owner:** pizmam (`[P]`) — with belengaz (`[B]`) for CI wiring
> **Epic:** E07 Infrastructure (cross-cutting launch readiness)
> **Branch:** `feature/pizmam-P43-aso`
> **Estimate:** ~5 developer-days (3 pipeline + 1 content + 1 review/polish)
> **Tier:** Medium-Large (15+ files across 3 platforms + CI + docs)
> **Status:** Planning
> **Produced via:** `.agent/workflows/plan.md` (Socratic gate + Specialist Synthesis Protocol)

---

## 1 · Goal & Non-Goals

### Goal
Deliver a **reproducible, localized, CI-integrated** App Store Optimization (ASO) and
screenshot pipeline for iOS App Store Connect and Google Play Console so that:

1. **Every release** can be shipped to both stores without manual Photoshop work.
2. Screenshots + metadata are **version-controlled, reviewable in PRs**, and regenerated
   automatically when UI or locale copy changes.
3. Store listings are **fully localized (NL + EN)** and compliant with EAA, GDPR, and
   App Store Review Guidelines §2.3 / §5.1.1 and Play Console policy.
4. ASO keywords are **evidence-based** (not guessed) and tied to Dutch P2P-marketplace
   search demand.

### Explicit Non-Goals (deferred to follow-on tasks)
- In-app store-ratings prompt (separate task — part of retention epic)
- Preview video production (can be added in a follow-on if marketing requests it)
- A/B testing of store listings (Play Console Experiments) — enable in post-launch sprint
- Paid UA creative (Meta/TikTok ads) — marketing team, not engineering
- Backlink/web landing-page SEO — owned by marketing, separate repo

---

## 2 · Current-State Audit

| Area | Current State | Gap |
|:-----|:--------------|:----|
| iOS metadata | `ios/Runner/Info.plist` only has `CFBundleDisplayName` + `CFBundleName` | No store-facing copy anywhere |
| Android metadata | `android/app/src/main/AndroidManifest.xml` only has `android:label` | No store-facing copy |
| Screenshots | None committed; no automation | Full greenfield |
| Fastlane | Not installed (`fastlane/` absent) | Need full setup |
| Integration tests | `integration_test/` folder absent | Must bootstrap |
| Golden tests | None under `test/` | Greenfield |
| Seed data | Mock repos under `lib/core/data/mock/` (already excluded from coverage) | Good — reusable |
| Screen specs | 31 spec files under [docs/screens/](docs/screens/) — complete | Ready to mine for "hero" screens |
| Localisation | Full NL + EN coverage via `easy_localization` in `assets/l10n/*.json` | Ready to extend with ASO keys |
| CI | `.github/workflows/ci.yml` exists with Flutter jobs | Extend, don't rebuild |

**Risk flag:** Store listings are the single highest-leverage surface for install
conversion. A malformed privacy-labels submission can block App Store review for
2–3 weeks; a policy-violating screenshot (e.g. uncovered user data) can delist the
app. **This task ships the guardrails, not just the assets.**

---

## 3 · Specialist Synthesis (per planningMandates)

### 3.1 `security-reviewer` — Threat Assessment
| Threat | Mitigation | Test |
|:-------|:-----------|:-----|
| **PII leakage in screenshots** (real user names, emails, addresses, phone numbers) | Use dedicated `SeedData.screenshotMode` profile with curated fictitious persons (pre-cleared for PR use); gitignored `.screenshot-redaction.txt` for any accidental real-data run | CI step: OCR each generated PNG and fail if matches `@deelmarkt-staff.eu` or Dutch phone/BSN patterns |
| **Secret leakage in store metadata** (API keys accidentally pasted in descriptions) | `detect-secrets` already runs pre-commit; extend baseline to include `fastlane/metadata/**` | Pre-commit hook |
| **Trademark / IP in screenshots** (competitor logos visible in "example" listings) | Seed data only uses generic public-domain product photos + DeelMarkt-authored stock | Manual review checklist in PR template |
| **Push-notification text visible in screenshots** revealing staging URLs | Disable push permission prompt in screenshot build flavor; mock notification center | Integration test flag `--dart-define=SCREENSHOT_MODE=true` |
| **Cookie / consent banner visible** on web screenshots | Pre-accept in screenshot flavor | Widget test assertion |

### 3.2 `tdd-guide` — Test Strategy
| Layer | Test Type | Coverage Target |
|:------|:----------|:----------------|
| `ScreenshotSeedData` mock builder | Unit | 100% (pure data) |
| Per-screen driver in `integration_test/screenshots/` | Integration | All 31 mapped screens compile + drive without exception |
| `store_metadata_lint.dart` validator | Unit | 100% |
| `keyword_budget.dart` (char counter) | Unit | 100% |
| Golden-image diffing for "hero" screenshots (regression) | Golden | 10 canonical screens × 2 locales × 3 devices = 60 goldens |
| ASO copy lint (profanity, trademark, App Store 2.3.10) | Unit | 100% of copy-linter |

**Test Pyramid Rule:** 60 % unit / 30 % integration / 10 % golden — goldens are brittle,
limited to the hero set.

### 3.3 `architect` — Architecture Impact
- **New top-level folders:** `integration_test/screenshots/`, `fastlane/`, `docs/marketing/aso/`
- **No changes to production code paths.** All screenshot logic gated behind
  `const bool kScreenshotMode = bool.fromEnvironment('SCREENSHOT_MODE')`.
  Violating this is a CI-blocking lint.
- **No new production runtime dependencies.** `screenshot`, `integration_test`,
  and `fastlane` are dev/tool-only.
- **Design-system invariant preserved:** screenshot driver reads l10n via the
  real `easy_localization` stack (no hardcoded strings).
- **Determinism:** freeze `DateTime.now()` via injected `Clock`
  (`package:clock`) so that "2 hours ago" in chat thread is stable across runs.

---

## 4 · Deliverables (ordered by dependency)

### WS-A · Infrastructure Bootstrap (Day 1)
| File | Purpose |
|:-----|:--------|
| `integration_test/screenshots_test.dart` | Entry point; delegates to per-screen drivers |
| `integration_test/screenshots/README.md` | How to run locally + CI |
| `integration_test/screenshots/_support/seed_data.dart` | Deterministic fictitious data (8 personas, 12 listings, 6 conversations) |
| `integration_test/screenshots/_support/screenshot_driver.dart` | Wraps `tester.pumpWidget` with seed providers + `Clock.fixed(DateTime(2026,4,15,14,0))` + locale override |
| `integration_test/screenshots/_support/device_frames.dart` | Maps DevicePixelRatio + size for each target device |
| `pubspec.yaml` (dev_dependencies) | `integration_test`, `screenshot: ^3.0.0`, `patrol_finders: ^2.2.0` (optional), `clock: ^1.1.1` |

**Verify (WS-A):** `flutter test integration_test/screenshots_test.dart` runs
end-to-end in headless mode on macOS + Linux CI and produces 0 artefacts yet (smoke test only).

---

### WS-B · Screen Drivers (Day 2)
Ten **hero** screens — these are the screens most likely to drive install:
| # | Screen file | Spec | Why hero |
|:--|:------------|:-----|:---------|
| 1 | `home_screen.dart` | [02-home/01-home-buyer.md](docs/screens/02-home/01-home-buyer.md) | First impression for browsing buyers |
| 2 | `listing_detail_screen.dart` | [03-listings/01-listing-detail.md](docs/screens/03-listings/01-listing-detail.md) | Price, photos, trust signals |
| 3 | `listing_creation_screen.dart` | [03-listings/02-listing-creation.md](docs/screens/03-listings/02-listing-creation.md) | Seller value prop |
| 4 | `category_browse_screen.dart` | [02-home/04-category-browse.md](docs/screens/02-home/04-category-browse.md) | Depth of inventory |
| 5 | `search_screen.dart` | [02-home/03-search.md](docs/screens/02-home/03-search.md) | Discovery power |
| 6 | `chat_thread_screen.dart` | [06-chat/02-chat-thread.md](docs/screens/06-chat/02-chat-thread.md) | Scam-alert + safety |
| 7 | `transaction_detail_screen.dart` | [04-payments/03-transaction-detail.md](docs/screens/04-payments/03-transaction-detail.md) | Escrow trust |
| 8 | `shipping_qr_screen.dart` | [05-shipping/01-shipping-qr.md](docs/screens/05-shipping/01-shipping-qr.md) | Unique vs competitors |
| 9 | `own_profile_screen.dart` | [07-profile/01-own-profile.md](docs/screens/07-profile/01-own-profile.md) | Badges / verified trust |
| 10 | `suspension_gate_screen.dart` ↔ **replaced** by [02-home/02-home-seller.md](docs/screens/02-home/02-home-seller.md) | Seller-mode home — shows earning potential |

Per screen: `integration_test/screenshots/<screen>_screenshot_test.dart` captures
**light + dark × NL + EN × {6.7" iOS, 6.5" iOS, 5.5" iOS, iPad 12.9", Android phone, Android tablet}** = 24 variants × 10 screens = **240 PNGs per run**.

**Determinism contract (every driver MUST):**
```dart
await tester.pumpAndSettle(const Duration(seconds: 2));
expect(find.byType(CircularProgressIndicator), findsNothing);
await binding.takeScreenshot('hero_home_buyer_ios67_nl_light');
```

**Verify (WS-B):** `flutter test integration_test/screenshots_test.dart --dart-define=SCREENSHOT_MODE=true`
produces all 240 PNGs deterministically (SHA-256 stable across 3 consecutive runs on macOS runner).

---

### WS-C · Fastlane Wiring (Day 3)
| File | Purpose |
|:-----|:--------|
| `fastlane/Fastfile` | Lanes: `ios_metadata`, `android_metadata`, `ios_screenshots`, `android_screenshots`, `deliver_dry_run` |
| `fastlane/Appfile` | App identifier, team_id, apple_id (via ENV) |
| `fastlane/Pluginfile` | `fastlane-plugin-supply` |
| `fastlane/metadata/en-US/**` + `nl-NL/**` | App name, subtitle, description, keywords, promotional_text, release_notes (one file each) |
| `fastlane/android/metadata/en-US/**` + `nl-NL/**` | title, short_description, full_description, video, graphics |
| `scripts/screenshots_to_fastlane.sh` | Moves `build/screenshots/` → `fastlane/screenshots/<locale>/<device>/` |
| `.github/workflows/screenshots.yml` | PR-triggered job that regenerates + diffs against committed PNGs |
| `ios/fastlane/precheck` config | Enforces App Store Review §2.3.10 (no placeholder text, no competitor refs) |

**App Store privacy nutrition labels:** declarative YAML at
`fastlane/metadata/review_information/privacy_details.yaml` — covers:
- Contact Info: email, phone (required by Supabase Auth)
- Identifiers: User ID (Supabase auth.users.id)
- Usage Data: product interaction
- Diagnostics: crash data (Sentry)
- **NOT linked to identity:** diagnostics; **Linked:** contact info + purchases
- **Used to track:** NO (no IDFA collection)

**Play Console Data Safety form:** `docs/marketing/aso/play_data_safety.md` as
source of truth; manually entered in Console (Play doesn't support fastlane for it).

**Verify (WS-C):** `bundle exec fastlane deliver_dry_run` exits 0 and prints
"Ready to submit" for both stores. CI job `screenshots.yml` passes on dev.

---

### WS-D · ASO Content (Day 4)

#### Keyword research
- Use Sensor Tower / App Annie free tier OR `aso-keyword-research` (npm) against
  seed list: `tweedehands`, `marktplaats alternatief`, `veilig verkopen`,
  `escrow app nederland`, `p2p marktplaats`, `gebruikte spullen verkopen`,
  `iDIN verificatie`, `dutch marketplace`.
- Evidence file: `docs/marketing/aso/keywords_research.md` — columns:
  **keyword | NL search volume | EN search volume | difficulty | DeelMarkt relevance (1–5) | used-in-locale**.
- Target: top 20 NL + top 20 EN.

#### Copy deliverables
| Asset | iOS limit | Android limit | File |
|:------|:----------|:--------------|:-----|
| App name | 30 | 30 | `fastlane/metadata/<lang>/name.txt` |
| Subtitle | 30 | — | `fastlane/metadata/<lang>/subtitle.txt` |
| Short description | — | 80 | `fastlane/android/metadata/<lang>/short_description.txt` |
| Promotional text | 170 | — | `fastlane/metadata/<lang>/promotional_text.txt` |
| Description | 4000 | 4000 | `fastlane/metadata/<lang>/description.txt` + Android counterpart |
| Keywords | 100 | (indexed from title + description) | `fastlane/metadata/<lang>/keywords.txt` |
| Release notes | 4000 | 500 | `fastlane/metadata/<lang>/release_notes.txt` |
| Support URL | URL | URL | `fastlane/metadata/<lang>/support_url.txt` |
| Marketing URL | URL | URL | `fastlane/metadata/<lang>/marketing_url.txt` |
| Privacy URL | URL | URL | must match `https://deelmarkt.com/privacy` |

#### Content principles
1. **No superlatives** that trigger Apple Review §2.3.2 ("#1", "best") unless verified.
2. **Feature truth** — every claim ("iDIN verified", "100% escrow protected") must map
   to a shipped feature; keep `docs/marketing/aso/claims_ledger.md` linking claim → code path.
3. **Dutch first** — all marketing copy drafted in NL, EN as translation. NL is the
   primary market.
4. **ASA (Apple Search Ads) discoverability** — avoid keyword stuffing; use natural
   phrasing that also ranks.

**Verify (WS-D):** `dart run scripts/check_aso.dart` validates:
- All copy under character limit
- No forbidden terms (competitor names, policy triggers)
- Every URL returns 200
- Keywords de-duplicated across title + subtitle + keywords
- Released-notes file not empty

---

### WS-E · Quality Gates + Docs (Day 5)
| File | Purpose |
|:-----|:--------|
| `docs/marketing/aso/README.md` | How to regenerate assets, how to update copy, release checklist |
| `docs/marketing/aso/release_checklist.md` | 21-item checklist (TestFlight/Internal → Prod) |
| `docs/PLAN-p43-aso.md` | **This file** — final plan committed |
| `scripts/check_aso.dart` | Copy lint + char budget + URL checker |
| `scripts/check_screenshots.sh` | PNG dimensions + file-size budget (< 8 MB each) + OCR PII scan |
| `.github/workflows/aso-validate.yml` | Runs both linters on every PR touching `fastlane/` or `docs/marketing/aso/` |
| `CLAUDE.md` (append §13) | Marketing assets are NOT modifiable by AI without explicit user approval |
| `docs/epics/E07-infrastructure.md` | Append P-43 acceptance criteria |

---

## 5 · Task List (Implementation Order)

### Phase 0 — Approval gate ✋
1. [ ] User approves this plan — no implementation until approved.

### Phase 1 — Bootstrap (WS-A)
2. [ ] Add dev deps to `pubspec.yaml` · **Verify:** `flutter pub get` clean
3. [ ] Create `integration_test/` skeleton + README · **Verify:** `flutter test integration_test/` runs (empty pass)
4. [ ] Implement `ScreenshotSeedData` · **Verify:** unit test seeds 8 personas + 12 listings deterministically (SHA-256 of JSON stable)
5. [ ] Implement `ScreenshotDriver` wrapper · **Verify:** widget test drives Home with seeded providers without calling real Supabase

### Phase 2 — Screen Drivers (WS-B)
6. [ ] Driver #1 Home (buyer) · **Verify:** 24 PNGs produced, pixel-stable across 3 runs
7. [ ] Drivers #2–#10 (one per hero screen) · **Verify each:** same determinism contract
8. [ ] Aggregate screenshots test entry point · **Verify:** single `flutter test` invocation produces all 240 PNGs

### Phase 3 — Fastlane (WS-C)
9. [ ] `fastlane init` (iOS + Android) committed · **Verify:** `fastlane lanes` lists all lanes
10. [ ] Script `scripts/screenshots_to_fastlane.sh` · **Verify:** after step 8, all PNGs land in correct fastlane dirs
11. [ ] Privacy labels YAML · **Verify:** manual checklist matches Apple docs
12. [ ] CI workflow `.github/workflows/screenshots.yml` · **Verify:** green on dev

### Phase 4 — ASO Content (WS-D)
13. [ ] Keyword research doc · **Verify:** 40 keywords (20 NL + 20 EN) with evidence columns
14. [ ] Draft all copy files NL + EN · **Verify:** `scripts/check_aso.dart` passes
15. [ ] Privacy labels filled · **Verify:** matches Privacy Policy URL content
16. [ ] Release-notes template (first version) · **Verify:** present for v1.0.0

### Phase 5 — Guardrails (WS-E)
17. [ ] `scripts/check_aso.dart` + `scripts/check_screenshots.sh` · **Verify:** both green locally
18. [ ] `.github/workflows/aso-validate.yml` · **Verify:** PR fails if copy exceeds budget
19. [ ] CLAUDE.md §13 (AI guardrail) · **Verify:** reviewed by human
20. [ ] Update SPRINT-PLAN.md mark P-43 `[x]` · **Verify:** CI green

### Phase 6 — Dry run
21. [ ] `bundle exec fastlane deliver_dry_run` iOS · **Verify:** zero warnings
22. [ ] `bundle exec fastlane supply --skip_upload_apk --track internal --dry_run` Android · **Verify:** zero warnings
23. [ ] Update epic E07 acceptance criteria · **Verify:** P-43 row complete

---

## 6 · Risks & Mitigations

| # | Risk | Likelihood | Impact | Mitigation |
|:--|:-----|:-----------|:-------|:-----------|
| R-1 | Flutter integration_test screenshot flakiness (fonts/scaling differs per host) | High | High | Pin exact font family + version in pubspec; run in Docker macOS image on CI; screenshot runs on one CI runner OS (macos-14) only |
| R-2 | App Store review rejects privacy labels mismatch | Medium | High (2-week delay) | WS-C includes Apple-compliant YAML + manual review checklist; test with TestFlight review first |
| R-3 | Keywords oversaturated — low ASO rank | Medium | Medium | Evidence-based research in WS-D; track rank weekly for 4 weeks after launch and iterate |
| R-4 | PII leaks in screenshots (e.g. dev left real phone in mock) | Low | Critical (GDPR) | OCR CI step; reviewer checklist; seed-data file is single source |
| R-5 | Screenshot PNGs bloat repo (>100 MB) | Medium | Medium | **Resolved via D-2:** Git LFS for `fastlane/screenshots/**` + 8 MB per-file budget + `pngquant` optimization |
| R-6 | Fastlane credentials leak | Low | Critical | Apple API key in GitHub Secrets (ASC_API_KEY_JSON); rotate every 90 days; never commit `.p8` files |
| R-7 | Localization drift — NL copy updates without EN | Medium | Low | `check_aso.dart` fails if any locale file has newer mtime than its peer |
| R-8 | Seed data becomes stale as features evolve | High | Medium | Link seed model via typed providers; failing provider type = failing CI |

---

## 7 · Acceptance Criteria (Epic E07 Amendment)

- [ ] Fastlane installed with metadata for **iOS + Android** in **NL + EN**
- [ ] 10 hero screens × 2 locales × 2 themes × 6 device classes = **240 screenshots** regenerated deterministically
- [ ] App Store privacy labels YAML committed and passes `deliver precheck`
- [ ] Play Console Data Safety form documented in `docs/marketing/aso/play_data_safety.md`
- [ ] ASO keyword research documented with evidence (40 keywords total)
- [ ] `scripts/check_aso.dart` fails on over-budget copy
- [ ] `scripts/check_screenshots.sh` fails on PII in screenshots (OCR) or file > 8 MB
- [ ] CI workflow regenerates screenshots on any `lib/` UI change and diffs against committed PNGs
- [ ] `bundle exec fastlane deliver_dry_run` passes for both platforms
- [ ] SPRINT-PLAN.md P-43 marked `[x]`
- [ ] docs/epics/E07-infrastructure.md acceptance criteria updated

---

## 8 · Cross-Cutting Concerns

### Security (mandate `rules/security.md`)
- All Apple / Google API credentials in **GitHub Secrets** only; never `.env` files
- `detect-secrets` baseline extended for `fastlane/` paths
- PII OCR scanner runs before PNGs are committed
- Supply-chain: pin `fastlane` version via `Gemfile.lock`, `dependabot` enabled

### Testing (mandate `rules/testing.md`)
- 80 % coverage on new Dart code (seed_data, driver, checkers)
- Goldens only for 10 hero "light EN 6.7-inch" — other 230 are regeneratable, not diffed
- No mocks for Supabase in screenshot mode — all via mock repositories (already in `lib/core/data/mock/`)

### Documentation (mandate `rules/documentation.md`)
- `docs/marketing/aso/` holds operational runbook
- `docs/epics/E07-infrastructure.md` gets acceptance criteria row
- `CLAUDE.md` §13 documents AI guardrails for marketing assets

### Performance (mandate `rules/performance.md`)
- Screenshot generation budget: ≤ 15 minutes full matrix on macOS-14 runner
- PNG optimization via `pngquant` post-processing; target 40–60 % size reduction

### Accessibility
- Hero screenshots MUST include at least one accessible-state image per screen (large text, high contrast) per App Store 2.5.2 — demonstrates EAA compliance
- Semantics labels present in screenshot mode (not stripped)

### Data privacy (mandate `rules/data-privacy.md`)
- Seed personas use `@example.invalid` emails, fictitious BSN-shaped placeholders, and fictional Dutch addresses (`Postbus 1234`, `1000 AB Amsterdam`)
- No Supabase project or Mollie test keys embedded in any committed artefact

---

## 9 · Agent Assignments

| Phase | Tasks | Agent | Domain |
|:------|:------|:------|:-------|
| 1 | WS-A bootstrap | pizmam | Frontend test infra |
| 2 | WS-B drivers | pizmam | Flutter widget/integration |
| 3 | WS-C fastlane + CI | belengaz | DevOps (workflow file ownership) |
| 4 | WS-D copy + research | pizmam (with marketing input) | Frontend / content |
| 5 | WS-E guardrails | pizmam + belengaz | Shared |

---

## 10 · Resolved Decisions (Phase 0)

| # | Question | Decision | Implications |
|:--|:---------|:---------|:-------------|
| D-1 | Screenshot host OS | **macOS-14 GitHub-hosted runner** | Budget ~$1.20/run; single canonical OS eliminates font-rendering drift (R-1) |
| D-2 | Screenshot storage | **Git LFS** for `fastlane/screenshots/**` | Add `.gitattributes` line: `fastlane/screenshots/**/*.png filter=lfs diff=lfs merge=lfs -text`; enable LFS in repo settings before first commit of PNGs |
| D-3 | Preview video | **Defer to post-launch** | Out of scope for P-43; create follow-up ticket after first ranking data (≥ 4 weeks post-launch) |
| D-4 | App Store Review contact | **support@deelmarkt.com + main support phone** | Capture in `fastlane/metadata/review_information/` — confirm on-call coverage during 24–48h review windows |
| D-5 | Marketing URL | **https://deelmarkt.com** (homepage, both locales) | Single canonical URL; privacy policy remains `https://deelmarkt.com/privacy` |

All five open questions are now resolved. Proceed to `/implement` on this branch when you're ready.

---

## 11 · Quality Score (self-validation per `plan-validation`)

| Rubric | Tier-Large max | Score |
|:-------|:--------------|:------|
| Goal clarity | 10 | 10 |
| Specialist synthesis present | 15 | 15 |
| File-path specificity | 20 | 20 |
| Verification per task | 20 | 20 |
| Cross-cutting coverage | 15 | 15 |
| Risk register | 10 | 10 |
| Domain enhancer (marketing, EAA, App Review Guidelines) | 10 | 10 |
| **Total** | **100** | **100** |

**Verdict:** PASS (100 % of tier max).

---

## 12 · Approval

- [ ] pizmam — planning owner
- [ ] belengaz — co-sign on fastlane + CI workflow ownership
- [ ] User — final approval to begin `/implement`
