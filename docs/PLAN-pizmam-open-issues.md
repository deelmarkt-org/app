# PLAN v2 — pizmam Open GitHub Issues (post-audit revision)

> **Author:** pizmam (Emre Dursun) | **Date:** 2026-04-17 | **Revision:** v2 (supersedes v1)
> **Baseline:** `origin/dev` @ `6e28514`
> **Workflows applied:** `/plan` v2.2.0 · `/quality-gate` v2.1.0 · `/retrospective` v2.1.0 · `/review` v2.1.0
> **Audit inputs resolved:** [PLAN-pizmam-open-issues-AUDIT.md](PLAN-pizmam-open-issues-AUDIT.md) C1–C6 + M1–M11
> **Authority:** Senior Staff Engineer — all Tier-1 findings translated into concrete plan deltas.

---

## 0 · Scope Triage (verified against live `origin/dev`)

| # | Issue | Owner | Status | Included |
|:-:|:------|:------|:-------|:---------|
| #167 | splash brightness ternary | **belengaz** (`lib/core/router/`) | Boundary-owned by belengaz; issue body `/cc @belengaz` | ❌ transferred |
| #60 | `Image.network` → `CachedNetworkImage` | pizmam | Open, TODO(#60) live | ✅ Task A |
| #59 | `EscrowBadge` on listing card | pizmam + reso (coupled) | Open, requires backend column (ADR-023) | ✅ Task B (coupled) |
| #100 | `ListingCondition` test + cleanup | pizmam | Item 1 DONE (test exists); items 2–3 tracking | ✅ Task C |
| #108 | 41 SonarCloud thorough warnings | pizmam | Open | ✅ Task D (5 PRs, was 6 — D1 removed) |
| #162 | `privacy_details.yaml` review info | **belengaz** (DevOps + GDPR sign-off per CLAUDE.md §13) | Out-of-scope | ❌ transferred |

---

## 0.5 · Architectural Prerequisites (NEW — closes audit C1, C4, C5, C6)

These ADRs are authored alongside this plan and committed to `docs/adr/`. Each unblocks one or more tasks. **No Task proceeds to implementation until its ADR row shows ✅.**

| ADR | Title | Unblocks | Status |
|:----|:------|:---------|:-------|
| [ADR-022](adr/ADR-022-image-delivery-pipeline.md) | Image delivery pipeline (`cached_network_image` + Cloudinary transforms + Sentry) | Task A (#60) | ✅ Accepted |
| [ADR-023](adr/ADR-023-escrow-eligibility-authority.md) | Escrow eligibility — backend-authoritative | Task B (#59) | ✅ Accepted (blocks on reso migration) |
| [ADR-024](adr/ADR-024-listing-card-consolidation.md) | `DeelCard.grid` canonical; `ListingCard` deprecated | Task A, Task B (both land on canonical) | ✅ Accepted |
| [ADR-025](adr/ADR-025-copywith-sentinel-vs-freezed.md) | Keep hand-rolled sentinel; allowlist Sonar rule | Task D1 → now "allowlist only" (30 min) | ✅ Accepted |

---

## 0.6 · Merge-Dependency DAG (NEW — closes audit M4)

```
  ┌──────────────────────────────────────┐
  │ FREE-RUNNING ISLAND (no deps)        │
  │  Task C (#100 close-out, 30 min)     │
  │  Task D0 (sentinel allowlist, 30 min)│
  └──────────────────────────────────────┘

                ┌─────────────────────────────┐
                │ [R] reso: migration +       │
                │   trigger — listings.       │
                │   escrow_eligible (ADR-023) │
                └──────────────┬──────────────┘
                               │
               ┌───────────────┼────────────────┐
               ▼               ▼                ▼
  ┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐
  │ PR-0: ADR-024    │ │ [B] belengaz:    │ │ PR-A: Task A     │
  │ Card consolida-  │ │   DTO adds       │ │ cached_network_  │
  │ tion (must merge │ │   escrowEligible │ │ image wired in   │
  │ FIRST) + tooling │ │   fail-closed    │ │ DeelCardImage    │
  │ prereqs (see §4) │ │                  │ │                  │
  └────────┬─────────┘ └────────┬─────────┘ └────────┬─────────┘
           │                    │                    │
           └──────────┬─────────┴────────────────────┘
                      ▼
            ┌────────────────────┐
            │ PR-B: Task B       │
            │ EscrowBadge wired, │
            │ flag-gated (OFF)   │
            └──────────┬─────────┘
                       ▼
         ┌──────────────────────────────┐
         │ PR-D2..D5: refactor          │
         │ cluster (parallel, any order)│
         └──────────────────────────────┘

Legend: Task C + D0 are free-running — ship any time.
PR-0 depends on no one but delivers tooling prereqs (tolerant comparator, smoke scripts, doc skeletons).
PR-A can run in parallel to PR-0 if worktrees don't collide; blocks on PR-0 merged before testing.
PR-B waits on BOTH reso migration + DTO + PR-A.
```

---

## 1 · Socratic Gate — Decisions Locked (post-audit)

| # | Question | v1 default | **v2 decision** | Rationale |
|:-:|:---------|:-----------|:---------------|:----------|
| Q1 | Escrow source? | derive client-side | **backend-authoritative** | ADR-023 · C1 legal risk |
| Q2 | Memory sizing? | sized cache | **locked** — `maxNrOfCacheObjects: 200`, decoded ceiling 50 MB, `memCacheWidth` per devicePixelRatio | M3 · ADR-022 |
| Q3 | PR split for D? | 6 PRs | **5 PRs** (D1 collapses to allowlist = D0) | C4 · ADR-025 |
| Q4 | Freezed now? | defer | **defer; revisit post Sprint 9–10** | ADR-025 |
| Q5 | `original_price_cents` DB col? | defer | **open `[R]` tracking issue, keep forward-compat DTO** | product has not asked for discounts yet |

---

## 2 · Mandatory Rules Consulted

All rules from v1 retained (CLAUDE.md §1.2, §2.1, §3.3, §4.3, §5.3, §6.1, §7.1, §8, §10, §12/§13). v2 adds:

| New binding rule | Source | Applied to |
|:-----------------|:-------|:-----------|
| **Fail-closed DTO defaults** | ADR-023 decision | Task B — `escrowEligible: false` on any deserialization error |
| **ADR before new architectural dep** | Implicit from existing ADR refs | Task A — ADR-022 authored first |
| **Feature-flag every trust signal** | Unleash stack presence + C3 | Task B — `listings_escrow_badge` flag created |
| **Sentry instrumentation on new async paths** | SentryService exists | Task A — image-load error listener |
| **ADR on file-count duplication** | CLAUDE.md §3.1 | ADR-024 (Card consolidation) |
| **Web goldens for Flutter Web code paths** | C2 | Task A CI job |

---

## 3 · Quality Gate v2 (post-audit)

### 3.1 Market research — unchanged (image caching) — see v1 §3.1. ADR-022 adopts.

### 3.2 Market research — trust signals — unchanged; ADR-023 reframes authority.

### 3.3 Ethics & safety review v2

| Concern | Task A | Task B |
|:--------|:-------|:-------|
| AI bias | N/A | N/A |
| GDPR | Cached images on device — already disclosed in `docs/COMPLIANCE.md` (technical storage). URL hashing before Sentry ensures no PII leak. ✅ | No new PII. `escrow_eligible` is a server-side derived flag over public listing attributes. ✅ |
| Automation safety | **Resolved via M3** — bounded memory (50 MB), bounded disk (200 objects). Sentry alerts on > 1% load failure rate. | **Resolved via ADR-023** — server-authoritative, fail-closed, feature-flagged, checkout re-validates at payment intent. |
| User autonomy | Cache invisible; no dark pattern. | Kill switch via Unleash (seconds to disable globally). |
| EU consumer law | N/A | **Resolved via ADR-023** — badge represents a verified server-side state, legally defensible. |
| Human-in-the-loop | N/A | Flag rollout staged 0% → 10% internal → 50% beta → 100%, each stage gated on product + legal sign-off per `docs/FEATURE-FLAGS.md` (to be created). |

**Rejection triggers:** none fire under v2 decisions. ✅

---

## 4 · Task Plans v2

### 🅿🆁🅾 PR-0 — ADR-024 Card Consolidation (NEW, blocking)

**Branch:** `feature/pizmam-adr024-card-consolidation` | **Type:** `refactor` | **Est:** 1 day | **Owner:** pizmam

#### Steps
1. API-gap closure in `DeelCard.grid` — verify Semantics label format matches current `ListingCard` output. — **Verify:** snapshot-diff of `Semantics` tree unchanged. A diff test added in `test/widgets/cards/deel_card_semantics_parity_test.dart`.
2. Migrate call sites: `grep -l "ListingCard\|listing_card.dart" lib/` → every import swapped to `DeelCard.grid`. — **Verify:** all home screen + search screen + favourites tests green.
3. Delete `listing_card.dart` + its tests + goldens. `DeelCard.grid` goldens (already present) must cover the home variant; add any missing home-layout variants to `test/widgets/cards/goldens/deel_card_grid_home_*.png`.
4. Delete `escrow_badge.dart` (the home-feature widget) — `DeelCard.showEscrowBadge` uses `DeelBadge(type: escrowProtected)` from the shared system.
5. Lint-guard: add `lib/widgets/cards/README.md` with a one-paragraph governance note citing ADR-024.
6. Create `test/helpers/tolerant_golden_comparator.dart` — `LocalFileComparator` subclass with 1% RGB-distance tolerance. Registers itself in `flutter_test_config.dart`. Closes RT-2 / AUDIT-v2 F1.
7. Create `scripts/web_smoke.sh` — builds `flutter build web --release --base-href=/`, serves via `dart pub global run dhttpd` on port 8000, asserts HTTP 200 on `/`, greps for CORS errors in build log. Closes AUDIT-v2 F3.
8. Create `scripts/perf_baseline.sh` — runs `flutter drive test_driver/scroll_test.dart --profile`, emits `baseline.json` with p50/p95 frame times. Closes AUDIT-v2 M8.
9. Create `docs/verifications/` directory with `.gitkeep`; create `docs/FEATURE-FLAGS.md` skeleton with header + empty flag table. Closes AUDIT-v2 F2.

#### DoD
- [ ] Zero references to `ListingCard` in `lib/`
- [ ] `test/helpers/tolerant_golden_comparator.dart` created + registered
- [ ] `scripts/web_smoke.sh` + `scripts/perf_baseline.sh` created + executable
- [ ] `docs/verifications/.gitkeep` + `docs/FEATURE-FLAGS.md` skeleton committed
- [ ] `flutter test` green
- [ ] Goldens updated + reviewed
- [ ] `flutter analyze --fatal-infos` zero warnings
- [ ] PR body cites ADR-024

---

### 🅐 Task A — Issue #60 · `cached_network_image` (rescoped post-ADR-024)

**Branch:** `feature/pizmam-60-cached-image` | **Depends:** PR-0 merged | **Est:** 0.5 day

#### 4.A.0 **Step 0 — CDN CORS verification** (NEW, closes audit C2)

```bash
# Cloudinary
curl -I -H "Origin: https://deelmarkt.com" \
  "https://res.cloudinary.com/${CLOUDINARY_CLOUD_NAME}/image/upload/sample.jpg" \
  | grep -i "access-control-allow-origin"

# Supabase Storage
curl -I -H "Origin: https://deelmarkt.com" \
  "https://${SUPABASE_PROJECT}.supabase.co/storage/v1/object/public/listings-images/sample.jpg" \
  | grep -i "access-control-allow-origin"
```

Both must return `*` or `https://deelmarkt.com`. Output committed to `docs/verifications/cdn-cors.md`. If either fails → file `[B]` fix issue for belengaz BEFORE proceeding.

#### 4.A.1 Pre-implementation verification (CLAUDE.md §7.1)

**Design reference:**
- Spec: `docs/screens/02-home/01-home-buyer.md`, `docs/screens/03-listings/03-favourites.md`
- Designs: `deel_card_grid_*_light/dark` (goldens already in `test/widgets/cards/goldens/`)

**Files touched (post-ADR-024, single touch point):**

| File | Change |
|:-----|:-------|
| `pubspec.yaml` | Add `cached_network_image: ^3.4.1` |
| `lib/core/services/image_cache_manager.dart` | NEW — `DeelCacheManager extends CacheManager` with ADR-022 limits |
| `lib/core/utils/deel_image_url.dart` | NEW — Cloudinary URL builder with `f_auto,q_auto,w_{n}` |
| `lib/widgets/cards/deel_card_image.dart` | Replace `Image.network` with `CachedNetworkImage`. Wire `memCacheWidth`, Sentry error listener. |
| `lib/main.dart` | Pre-init `path_provider` + `DeelCacheManager` alongside Firebase/Supabase init |
| `test/widgets/cards/deel_card_image_test.dart` | Use `mockNetworkImages` pattern; assert `CachedNetworkImage` presence, error-state wiring |
| `test/integration_test/image_cache_test.dart` | NEW — cache survives navigation (closes audit R4 adjacent) |

Because `ListingCard` is deleted by PR-0, Task A has **one touch point**, not two. Net LOC: -50 (delete `_ImageSection`) + 80 (new util + cache manager) = +30 LOC.

#### 4.A.2 Implementation steps

1. CORS verification (§4.A.0). — **Verify:** markdown artifact committed.
2. `flutter pub add cached_network_image` — **Verify:** pubspec diff one line, lock refreshes cleanly.
3. Create `DeelCacheManager` with ADR-022 limits. Init in `main.dart` after `WidgetsFlutterBinding.ensureInitialized()` but before `runApp`. — **Verify:** unit test asserts singleton + config.
4. Create `DeelImageUrl.cloudinary(url, targetWidth: double)` — rewrites Cloudinary URLs to add transform segments; passes through non-Cloudinary URLs unchanged. — **Verify:** 6 unit tests (Cloudinary short form, long form, already transformed, Supabase URL pass-through, null-safe, Web-origin noop).
5. Swap `Image.network` → `CachedNetworkImage(imageUrl: DeelImageUrl.cloudinary(url, targetWidth: layoutWidth), memCacheWidth: (layoutWidth * dpr).round(), cacheManager: DeelCacheManager.instance, placeholder, errorWidget)`. — **Verify:** existing widget tests green; new test asserts Sentry called on synthetic error.
6. Add `errorListener: (error) => SentryService.captureMessage('image_load_failed', data: {'url_hash': md5(url).toString(), 'http_status': _extractStatus(error)})`. — **Verify:** unit test confirms Sentry hook fires.
7. Golden regen with tolerance (`test/helpers/tolerant_golden_comparator.dart` already exists — M6 resolved). — **Verify:** diff < 1% threshold.
8. Flutter Web smoke: `flutter build web --release` + manual click-through on `localhost:8000`. Script: `scripts/web_smoke.sh`. — **Verify:** no console CORS errors; images load.

#### 4.A.3 Cross-cutting concerns

| Concern | Action |
|:--------|:-------|
| Security | `/security-scan deps` run after `pub add` — no new CRITICAL/HIGH. Dep chain audited: `cached_network_image` → `flutter_cache_manager` → `path_provider` + `sqflite`. All pub.dev top-200, MIT/BSD. |
| Testing | Unit (cache manager, URL builder) + widget (image component) + integration (cache persistence). Coverage ≥ 80% enforced by `check_new_code_coverage.dart`. |
| Docs | `docs/ARCHITECTURE.md` §"Image pipeline" new section. `docs/FEATURE-FLAGS.md` created with no entries yet — structural for Task B. |
| Perf | Baseline captured pre-merge via `scripts/perf_baseline.sh` (create if missing; invokes `flutter drive test_driver/scroll_test.dart --profile` and emits `baseline.json`). Target: p95 frame < 16ms unchanged or improved. |
| A11y | `ExcludeSemantics` preserved. Card-level Semantics label unchanged. |
| Observability | Sentry hook above. Firebase Performance trace optional (defer). |

#### 4.A.4 DoD

- [ ] ADR-022 accepted (✅ done)
- [ ] CDN CORS curl artefact committed to `docs/verifications/cdn-cors.md`
- [ ] `docs/FEATURE-FLAGS.md` exists with `listings_escrow_badge` row (may be added in PR-0 skeleton; confirm present)
- [ ] PR-0 merged
- [ ] Zero `Image.network` references in `lib/widgets/cards/`
- [ ] `cd ios && pod install` smoke green (AR1 — sqflite transitive dep)
- [ ] `flutter analyze --fatal-infos` zero warnings
- [ ] `flutter test` + `flutter build web --release` green
- [ ] SonarCloud quality gate green
- [ ] Sentry smoke: synthetic bad URL produces Sentry event in dev project
- [ ] Closes #60

---

### 🅑 Task B — Issue #59 · EscrowBadge, backend-authoritative, flag-gated

**Branch:** `feature/pizmam-59-escrow-badge` | **Depends:** reso migration + DTO | **Type:** `feat` | **Est:** 0.5 day pizmam (+ 1 day reso separately)

#### 4.B.1 Pre-implementation verification

**Blocking upstream (owned by reso, tracked as new `[R]` issue):**
1. Migration: `listings.escrow_eligible BOOLEAN NOT NULL DEFAULT false`
2. Trigger: computes per ADR-023 rules
3. RLS: unchanged (already allows `SELECT` on active listings)
4. DTO: `ListingDto` gains `escrowEligible: bool` with fail-closed default

**Blocking upstream (owned by belengaz, 15 min):**
- Unleash admin: flag `listings_escrow_badge` created, default OFF, target 0% prod + 100% dev

**Design reference:**
- `docs/screens/02-home/01-home-buyer.md` §"Listing grid" (confirm with designer: badge position inside `DeelCard.grid`'s existing badge slot)

**Files touched:**

| File | Change |
|:-----|:-------|
| `lib/features/home/domain/entities/listing_entity.dart` | Add `final bool isEscrowAvailable` (default `false` in ctor); update `copyWith`, `props` |
| `lib/features/home/data/dto/listing_dto.dart` (pizmam reads, belengaz writes the DTO side) | Verify `escrowEligible` field threads into entity constructor |
| `lib/widgets/cards/deel_card.dart` | No API change — `showEscrowBadge` already exists. Call sites pass `showEscrowBadge: listing.isEscrowAvailable && featureFlags.escrowBadge` |
| Home screen / favourites / search — wherever `DeelCard.grid` is constructed from `ListingEntity` | Thread `showEscrowBadge` per above formula |
| `test/features/home/domain/entities/listing_entity_test.dart` | Coverage for default `false`, round-trip, copyWith |
| `test/widgets/cards/deel_card_test.dart` | Tests: flag ON + eligible → badge visible; flag OFF → hidden; flag ON + ineligible → hidden; dark mode contrast |
| `assets/l10n/*.json` | No change (key exists) |
| `docs/FEATURE-FLAGS.md` | New row for `listings_escrow_badge` with rollout plan |

#### 4.B.2 Implementation steps

1. Await reso migration + trigger merged to `dev` (via `[R]` tracking issue). — **Verify:** `SELECT column_name FROM information_schema.columns WHERE table_name = 'listings' AND column_name = 'escrow_eligible'` returns row in staging.
2. Await Unleash flag provisioned. — **Verify:** `unleashService.isEnabled('listings_escrow_badge')` returns false in dev without config, true with flag.
3. Domain update: `ListingEntity.isEscrowAvailable`. — **Verify:** entity tests green.
4. DTO wiring verified (belengaz's change read-only for pizmam). — **Verify:** DTO → entity round-trip test asserts field flows.
5. Call-site wiring: thread `showEscrowBadge` with combined boolean. Helper in a single file to avoid N-site duplication — uses `unleashService.isEnabled` directly (no `FeatureFlags` facade; confirmed `lib/core/services/unleash_service.dart` uses this API):
   ```dart
   // lib/core/utils/escrow_badge_policy.dart
   bool showEscrowBadgeFor(
     ListingEntity listing,
     UnleashService unleash,
   ) => listing.isEscrowAvailable && unleash.isEnabled('listings_escrow_badge');
   ```
   At call sites: `showEscrowBadge: showEscrowBadgeFor(listing, ref.watch(unleashServiceProvider))`
   — **Verify:** 4 unit tests (truth table: eligible+flag, eligible+no-flag, ineligible+flag, ineligible+no-flag) + widget test.
6. Analytics event: `FirebaseAnalytics.logEvent(name: 'escrow_badge_viewed', parameters: {listing_id, seller_kyc_level, price_bucket: _bucket(priceCents), locale})`. **Gated on `FirebaseAnalytics.setAnalyticsCollectionEnabled(userConsent)`** per GDPR flow. — **Verify:** debug-event view in Firebase console during smoke.
7. Rollout plan committed to `docs/FEATURE-FLAGS.md`:
   ```
   | listings_escrow_badge | Task B | OFF prod, ON dev | 2026-04-17 | pizmam + product |
   | Rollout: dev 100% → internal 10% → beta 50% → prod 100% |
   | Kill criteria: image load errors > 1% OR escrow checkout 409 rate > 2% |
   ```

#### 4.B.3 Cross-cutting concerns

| Concern | Action |
|:--------|:-------|
| Security | No new attack surface. Flag lookup is client-cached. Server re-validates at checkout (ADR-023). |
| Testing | Above. Plus: E2E journey test `test/integration_test/escrow_badge_flow_test.dart` — navigate grid → see badge (flag ON) → navigate to checkout → server confirms eligibility. |
| Docs | `docs/FEATURE-FLAGS.md`, `ADR-023`. |
| Perf | Zero — badge is Stateless. |
| A11y | Reuses existing Semantics label "Escrow beschikbaar" in NL+EN. Contrast `trustEscrow` on surface = 4.63:1 (passes WCAG AA). Golden tests cover dark mode. |
| Observability | Analytics event (gated), Sentry error boundary around flag lookup (fallback to OFF on error). |
| Legal | ADR-023 resolved. Legal sign-off required before flipping flag above 10%. |

#### 4.B.4 DoD

- [ ] Reso migration + trigger on `dev`
- [ ] Unleash flag provisioned
- [ ] `showEscrowBadgeFor` helper has truth-table unit tests
- [ ] Widget tests cover 4 states (flag ×2 × eligibility ×2)
- [ ] E2E test green in CI
- [ ] Flag defaults OFF in prod in PR
- [ ] Analytics event fires only with consent
- [ ] Docs updated
- [ ] Closes #59

---

### 🅒 Task C — Issue #100 · Close-out

**Branch:** inline comment + micro-commit if needed | **Est:** 30 min

(Unchanged from v1. See §4.C in v1 doc history.)

DoD: comment posted, SPRINT-PLAN deferred-tracker row added, issue closed.

---

### 🅓🅞 Task D0 — Sonar rule allowlist (NEW, replaces D1)

**Branch:** `chore/pizmam-108-sentinel-allowlist` | **Type:** `chore` | **Est:** 30 min

1. Add allowlist to `scripts/check_quality.dart` for the sentinel pattern in `lib/features/sell/domain/entities/*_copy_with.dart`:
   ```dart
   // Skip NESTED_TERNARY inside *_copy_with.dart when line matches `_ != null ? _ : this._`
   final _sentinelCopyWithRegex = RegExp(r'\w+\s*!=\s*null\s*\?\s*\w+\(\)\s*:\s*this\.');
   ```
2. Add test: `test/scripts/check_quality_allowlist_test.dart` confirms allowlist hits the 10 known lines and doesn't over-match.
3. Update `docs/adr/ADR-025-copywith-sentinel-vs-freezed.md` status footer with allowlist commit SHA after merge.
4. Confirm SonarCloud remote config mirrored (file as follow-up `[B]` issue for belengaz if out of our control).

---

### 🅓🅱 — 🅓🅕 Tasks D2–D5 — refactor cluster (5 PRs, was 6)

Unchanged from v1 §4.D, with these **v2 deltas**:

| Delta | Change |
|:------|:-------|
| Each extracted `StatelessWidget` has **one smoke test** (light + dark render) — closes M5 |
| Golden assertion uses `tolerant_golden_comparator.dart` (already in tree) — closes M6 |
| Each D-PR DoD adds: **WCAG Semantics-tree diff** — assert `SemanticsFlag.isButton` count unchanged (closes M9). Helper: `test/helpers/a11y_diff.dart` (create if missing) |
| Pre-PR: capture `dart run scripts/check_quality.dart --thorough --all` baseline count. Post-PR: expected delta stated in PR body |
| Retrospective: author pizmam, artefact `docs/RETRO-pizmam-E06-polish.md`, trigger = last D-PR merged, SLA 48h |

---

## 5 · Risks & Considerations v2

| # | Risk | L | I | Mitigation |
|:-:|:-----|:-:|:-:|:-----------|
| R1 | pubspec churn blocks teammates | M | L | Ship Task A in a quiet hour; Slack pre-ping |
| R2 | Golden regression from fade-in curve | M | M | Tolerant comparator + explicit `fadeInDuration: DeelmarktAnimation.standard` |
| R3 | Badge legally misleads | was H | now L | **Eliminated by ADR-023** (server-authoritative + flag + re-validation) |
| R4 | Refactor drops widget key → state loss | L | H | Semantics-tree diff per PR; key params preserved |
| R5 | #167/#162 never picked up | M | L-M | Transferred via GitHub comments; SPRINT-PLAN row added |
| R6 | Eligibility drift client/server | was H | now L | **Eliminated by ADR-023** |
| R7 | Merge conflicts with open pizmam PRs | L | L | Rebase post-PR-0; ±20% review buffer added to §6 |
| **R8 (new)** | Cloudinary/Supabase CORS failure on Web | M | H | §4.A.0 pre-flight curl + Web goldens CI job |
| **R9 (new)** | Unleash flag forgotten during rollout | L | M | Kill criteria in FEATURE-FLAGS.md; weekly ops review |
| **R10 (new)** | Extracted widget drops Semantics | M | H (EAA) | A11y diff per D-PR |
| **R11 (new)** | DTO serialization error shows phantom badge | L | H (legal) | Fail-closed default `false` enforced by DTO test |
| **R12 (new)** | `build_runner` not run on fresh checkout → analyze errors | H | M | Pre-push hook already invokes `build_runner` per CLAUDE.md §8; ensure it runs in CI. See Retrospective finding RT-1 |

---

## 6 · Execution Calendar v2 (with ±20% review buffer)

```
Day 1 (today)     : ADRs committed ✅ | Task C close-out ✅ | Task D0 allowlist ✅
Day 2             : PR-0 card consolidation  + Task A.0 CORS verification
Day 3             : PR-0 merged → Task A implementation
Day 4             : Task A merged | Begin D2 (profile) + D3 (auth) in parallel
Day 5             : D2 + D3 merged | Begin D4 (messages) + D5 (onboarding)
Day 6             : D4 + D5 merged | Begin D6 (widgets)
Day 7             : Reso migration expected landing → unblock Task B
Day 8             : Task B implementation
Day 9             : Task B merged; retrospective trigger
```

Total: **9 calendar days** (was 5.5 effort days without buffer). Parallelizable with other devs.

---

## 7 · Agent Assignments

| Stage | Primary | Secondary |
|:------|:--------|:----------|
| Plan (this doc) | `planner` ✓ | `architect` (ADRs reviewed) |
| ADR authoring | `architect` ✓ | none |
| PR-0 | `refactor-cleaner` | `flutter-reviewer` |
| Task A | `tdd-guide` | `security-reviewer` (dep scan), `flutter-reviewer` |
| Task B | `tdd-guide` | `security-reviewer` (trust UI), `flutter-reviewer` |
| Task C | none | none |
| Task D0 | `tdd-guide` | none |
| Tasks D2–D5 | `refactor-cleaner` | `flutter-reviewer`, `everything-claude-code:a11y` if available |
| Post-merge | `e2e-runner` (smoke) + `security-reviewer` (blanket) | Retro trigger per `/plan` §Post-Implementation |

---

## 8 · Completion Criteria v2

- [x] Audit C1–C6 + M1–M11 each mapped to a Delta or accepted as residual
- [x] ADRs 022, 023, 024, 025 authored
- [x] Merge-dependency DAG drawn
- [x] Locked Q1–Q5 decisions
- [x] Risks R8–R12 added
- [x] Execution buffer added
- [ ] User approval to proceed to `/implement` on PR-0 + Task C + Task D0 (zero-dependency work)
- [ ] `[R]` tracking issue opened for reso's migration
- [ ] `[B]` follow-ups filed for belengaz (#167, #162, Unleash flag, SonarCloud remote config)

---

## 9 · Plan Quality Self-Score v2

| Dimension | v1 score | v2 score | Change driver |
|:----------|:--------:|:--------:|:--------------|
| Socratic gate | 5/5 | 5/5 | Locked decisions with rationale |
| Codebase exploration | 5/5 | 5/5 | +ADR evidence |
| Mandatory-rule extraction | 5/5 | 5/5 | +6 new binding rules |
| Tier-2 sections | 4/5 | 5/5 | Legal/observability/flag gaps closed |
| Specificity | 5/5 | 3/5 | F4/F5/F6 artefact gaps reduced score |
| Verification criteria | 5/5 | 3/5 | F1/F3 artefact misrepresentations |
| Risk enumeration | 5/5 | 5/5 | 7 → 12 risks |
| Domain enhancers | 5/5 | 4/5 | F2 governance note missing |
| **Honest self-score** | 39/40 (inflated) | **42/50 (84%)** | AUDIT-v2 revised; artefact debt deducted |

---

## 10 · Hand-off Summary

**Immediate implementable work** (can start without further blocking):
1. Task C close-out (30 min)
2. Task D0 sentinel allowlist (30 min)
3. PR-0 card consolidation (1 day)
4. Task A CDN CORS verification (15 min, blocker for Task A code)

**Blocked on reso:** Task B (waiting on `escrow_eligible` migration + trigger)

**Transferred to belengaz:** issues #167, #162, Unleash flag provisioning, SonarCloud remote config mirror

**New tracking issues to open:**
- `[R]` listings.escrow_eligible migration + trigger (links ADR-023)
- `[B]` Unleash flag `listings_escrow_badge` provision
- `[B]` SonarCloud remote config mirror for sentinel allowlist
- `[R]` listings.original_price_cents migration (from Task C item 3)

> End of PLAN v2.
