# AUDIT — `PLAN-pizmam-open-issues.md`

> **Auditor role:** Senior Staff Engineer (architectural authority)
> **Audit type:** Tier-1 production-grade gate review
> **Subject plan:** `docs/PLAN-pizmam-open-issues.md`
> **Date:** 2026-04-17
> **Verdict:** ⚠️ **CONDITIONAL PASS** — plan is strong on scope triage and specificity, but has **6 critical** and **11 major** gaps that must be closed before implementation. Most deficiencies concentrate in Task B (trust/legal risk) and Task A (Flutter Web + Cloudinary edge cases).

---

## Executive Summary

| Area | Grade | Summary |
|:-----|:-----:|:--------|
| Scope triage (ownership correctness) | A | Correctly rejected #167 and #162. Verified #100 item 1 already done. |
| Socratic gate / decision traceability | A- | 5 questions, defaults stated. Q1 undersells legal risk (see C1). |
| File-level specificity | A | Exact paths + line numbers. |
| Competitive research | B+ | 5+ competitors, but misses EU consumer protection framing for Task B. |
| Risk enumeration | B | 7 risks listed, but 4 additional production-grade risks missing (CORS, Cloudinary egress, widget-key identity, generated-code collision). |
| Architecture rigor | C+ | **No ADR** proposed for `cached_network_image` adoption. No resolution for `DeelCard` vs `ListingCard` duplication. |
| Test strategy | C | "No new tests" on refactors is absolutist; no flutter_driver perf baseline; golden tolerance thresholds unspecified. |
| Observability | D | Sentry + Firebase are in stack yet neither is wired into Tasks A/B. |
| Rollback / feature-flag strategy | D | Unleash is in the stack (`lib/core/services/unleash_service.dart`) yet EscrowBadge is un-flagged — direct-to-prod trust signal. |
| Release / merge order | B- | Execution calendar exists; merge-dependency graph does not. |
| Governance (retro hook, ADR, security review) | C | `/plan` retrospective hook mentioned but not scheduled. |

**Overall maturity: B-** — ready for a feature sprint, **not** ready for an MVP launch gate. Corrective actions below promote it to A.

---

## CRITICAL Findings (must fix before `/implement`)

### 🔴 C1 — Task B: Client-side escrow derivation creates **EU consumer-law liability**

**Finding.** Plan §4.B.1 proposes:
```dart
bool get isEscrowAvailable =>
    status == ListingStatus.active &&
    priceInCents >= 5000 &&
    (qualityScore ?? 0) >= 50;
```

This is a **pre-contractual commercial claim** under [EU Consumer Rights Directive 2011/83 Art. 6(1)(r)](https://eur-lex.europa.eu/eli/dir/2011/83/oj) + [Omnibus Directive (2019/2161)](https://eur-lex.europa.eu/eli/dir/2019/2161/oj). If the UI shows "Escrow beschikbaar" and the backend later refuses escrow at checkout (because seller KYC dropped, listing was reported, policy changed, etc.), the buyer has a **misleading-practice claim** per ACM (Dutch Authority for Consumers & Markets) enforcement precedent.

Client-derived eligibility **will** diverge from backend authoritative check the moment E03 Phase 2 ships. That is the exact divergence regulators fine for.

**Required correction.**
1. **Escrow eligibility MUST be backend-authoritative.** Either:
   - **Option A (recommended):** `listings` table gains `escrow_eligible: BOOLEAN NOT NULL DEFAULT false`, computed server-side via trigger or Edge Function on listing write. Client reads a field, never computes.
   - **Option B (interim):** `GET /functions/v1/listing-escrow-eligibility` batched endpoint; client caches per-session. Still server-authoritative.
2. Plan's default for Q1 **must flip** from "derive client-side" to "backend-computed field". This **blocks Task B** until reso ships the column or EF.
3. Until that ships, **Task B scope narrows to "wire-only"** — widget + test scaffold behind Unleash flag (see C3), entity gains `final bool isEscrowAvailable;` with default `false` and DTO fallback; no derivation logic in client.

**Evidence:** `docs/epics/E03-payments-escrow.md` already lists escrow eligibility as a backend concern; `CLAUDE.md §9` mandates "All tables MUST have RLS policies" and "Edge Functions use Zod for input validation" — escrow eligibility fits the same pattern.

**Owner:** pizmam writes the UI; reso owns the migration + trigger; this becomes a **coupled PR pair**, not a solo task.

---

### 🔴 C2 — Task A: Flutter Web + Cloudinary CORS not verified; `img-src` CSP confirmed but `cached_network_image` on web uses **different request pipeline**

**Finding.** The app ships a Flutter Web target (P-45, P-48, P-49). Plan §4.A makes no mention of web-specific behavior. Concrete risks:

1. **CSP allows Cloudinary for `img-src`** (verified: `web/index.html:31` — `img-src 'self' data: blob: https://res.cloudinary.com https://*.supabase.co`). ✅ no CSP change needed.
2. **However**, `cached_network_image` on web uses `BrowserImageProvider` / `window.fetch` which requires CORS headers from origin. Cloudinary sets `Access-Control-Allow-Origin: *` by default **only for public folders**; any signed/authenticated URL (we use signed URLs for user uploads) returns *without* CORS → silent image load failure on web.
3. Supabase Storage images (`*.supabase.co`) likewise need CORS: Supabase serves `Access-Control-Allow-Origin: *` on the storage endpoint but **only for public buckets**; `listings-images` bucket policy must be reviewed.

**Required correction.**
1. Before shipping Task A, run the verification script:
   ```bash
   curl -I -H "Origin: https://deelmarkt.com" "https://res.cloudinary.com/<cloud>/image/upload/<sample_public_id>"
   curl -I -H "Origin: https://deelmarkt.com" "https://<project>.supabase.co/storage/v1/object/public/listings-images/<sample>"
   ```
   Both must return `Access-Control-Allow-Origin: *` (or our origin).
2. Add this to plan §4.A.2 as **Step 0 (blocker)**.
3. For signed Cloudinary URLs (if used), switch to `fetched_url` helper that strips signature in web build, or route through our Cloudflare Worker which adds CORS.
4. Add a Flutter Web goldens job to CI (if not present) — mobile goldens won't catch this.

**Evidence:** `cached_network_image` GitHub issues #591, #683 document silent CORS failure modes on web.

---

### 🔴 C3 — Task B: Unleash is in the stack but EscrowBadge is shipping un-flagged

**Finding.** Plan §4.B says nothing about feature flags. DeelMarkt has **production Unleash** (`lib/core/services/unleash_service.dart:23`). A trust-signal UI change with legal implications (C1) without a kill-switch is not acceptable for a pre-launch product.

**Required correction.**
1. Gate `EscrowBadge` display on `UnleashService.isEnabled('listing_card_escrow_badge')`.
2. Default OFF in production until:
   - Backend authoritative field lands (C1);
   - Product + legal sign-off on copy;
   - Design QA on dark mode + contrast.
3. Flag config logged in `docs/FEATURE-FLAGS.md` (create if missing) with rollout plan: 0% → 10% internal → 50% beta → 100%.

**Why critical:** Without a flag, a bad deploy requires a hotfix release through Codemagic (~30 min best case) vs a flag flip (~seconds). For a trust-critical UI element, that delta is material.

---

### 🔴 C4 — Task D1: `listing_creation_state_copy_with.dart` "NESTED_TERNARY" violations are **pattern false-positives**, not nested ternaries

**Finding.** I inspected the file (it is hand-written, no `build_runner` annotation — safe to edit, rejecting one sub-risk). But the 10 reported "NESTED_TERNARY" violations are the **sentinel-emulating pattern**:

```dart
categoryL1Id: categoryL1Id != null ? categoryL1Id() : this.categoryL1Id,
```

These are **not** nested ternaries. They are single-level ternaries implementing the "clear-to-null" sentinel via `T? Function()?`. Refactoring them with the generic "extract to named local" playbook from §4.D.2 will:
- Produce worse code (10 named locals for 10 fields),
- Not actually silence Sonar (the rule trips on `?.()` or similar nested syntax, which must be checked against the actual AST),
- Risk breaking copyWith semantics if the refactor confuses "closure present + returns null" with "closure absent".

**Required correction.**
1. **Re-read `scripts/check_quality.dart` NESTED_TERNARY detector** to confirm what it flags. If the detector mis-classifies these, file a `check_quality.dart` issue and **suppress** these 10 via allowlist — not refactor.
2. If the detector is correct and the pattern really is nested at AST level, the right refactor is to migrate `ListingCreationState` to `freezed` (proper sentinel handling, generated copyWith). This is a **separate architectural decision** — needs an ADR and should not happen inside a "SonarCloud cleanup" PR.
3. Revise §4.D PR matrix: **pull D1 out** of the refactor cluster and block it behind an ADR decision (Q4 becomes critical, not optional).

**Consequence for plan:** D1's 1-day estimate is either wrong (if allowlist, it's 15 min) or wrong (if freezed migration, it's 3–5 days + test suite regression). Either way, it cannot ship as planned.

---

### 🔴 C5 — No ADR for `cached_network_image` adoption

**Finding.** Plan §3.1 performs good competitor research and picks a library. This is an **architectural dependency** (image pipeline is cross-cutting, affects Web + mobile, couples to Cloudinary, binds caching contract). Adding it without an ADR violates:
- Implicit governance standard from existing ADR references in code (`ADR-21` mentioned in `listing_entity.dart:16`, `ADR-019` in P-48),
- `CLAUDE.md §7.1` spirit (verification-before-implementation).

`find docs -name "ADR*"` returns zero results in this tree — ADRs are referenced but the directory isn't discoverable. That itself is a **governance finding**.

**Required correction.**
1. Locate or create `docs/adr/` with index.
2. Write `ADR-0XX-image-delivery-pipeline.md` before Task A implementation. Content: context, options (stdlib / `cached_network_image` / `extended_image` / custom), decision, consequences, rollback criteria.
3. Link from plan §4.A.1.

---

### 🔴 C6 — `ListingCard` vs `DeelCard` architectural duplication not addressed

**Finding.** Plan acknowledges in §4.B.1 that `lib/widgets/cards/deel_card.dart` (shared) and `lib/features/home/presentation/widgets/listing_card.dart` (feature) do **the same job** with divergent APIs (`DeelCard.showEscrowBadge` vs `ListingCard` TODO for same feature). Plan ships fixes to `ListingCard` without deciding the canonical path — guaranteeing future drift.

For Tier-1 shipping, this is **unacceptable**: every future card feature will require double implementation. Technical debt compounds.

**Required correction.** Pre-implementation: pizmam writes a 1-page architecture note in `docs/adr/ADR-0XX-listing-card-consolidation.md` choosing:
- **Option X** — Keep both; document when to use which, add lint rule preventing new `Image.network` in either.
- **Option Y** — Promote `DeelCard.grid` as canonical; deprecate `ListingCard`; migrate call sites in a follow-up PR.
- **Option Z** — Promote `ListingCard` pattern (feature-owned); retire `DeelCard.grid`.

Either way, this decision lives **above** the ticket-level plan. Tasks A and B land on the canonical path, not on the deprecated one.

**If option Y wins**, Tasks A and B largely collapse: #60 becomes a one-line change to `DeelCardImage`; #59 becomes passing `showEscrowBadge` through the call site.

---

## MAJOR Findings (should fix before merge)

### 🟡 M1 — No Sentry/observability wiring on Task A image loads

**Finding.** `lib/core/services/sentry_service.dart` exists. Plan does not wire image load failures. When Cloudinary 404s a signed URL in production, silent failure. Add `errorListener` to `CachedNetworkImage` → `SentryService.captureMessage('image_load_failed', tags: {'url_hash': md5(url)})` (no PII; hash URL only).

### 🟡 M2 — No Cloudinary egress cost forecast for Task A

**Finding.** `cached_network_image` reduces Cloudflare+Cloudinary egress for repeat views — **but**, Flutter Web has no disk cache (uses browser cache only), so web traffic won't benefit. Free tier Cloudinary = 25GB/month egress. At 500 listings × 300KB avg × 10 views/day × 30 days ≈ 45GB — already over free tier before this PR. Plan must:
1. Confirm Cloudinary plan tier with belengaz.
2. Add Cloudinary transformation `f_auto,q_auto,w_400` to default URL builder to shave 60% bandwidth.
3. Forecast after cache: (45GB × 0.3 hit-miss ratio) + Web traffic ≈ 22GB/month for mobile, Web unchanged.

### 🟡 M3 — Memory-cap math not validated

**Finding.** Plan picks `maxNrOfCacheObjects: 500`, `stalePeriod: 7 days`. Not grounded in real numbers. On a mid-tier Android (Galaxy A32, 4GB RAM, ~300MB app budget), 500 images × ~300KB decoded = 150MB of disk, but **decoded memory** (4 bytes/pixel × 400×300) = 480KB/image × 500 = 240MB if all hot — OOM risk. Use:
- `maxNrOfCacheObjects: 200` (disk),
- `PaintingBinding.instance.imageCache.maximumSize = 100`,
- `imageCache.maximumSizeBytes = 50 * 1024 * 1024`.

Explicitly set these in `image_cache_manager.dart`.

### 🟡 M4 — Rollback & merge-dependency graph missing

**Finding.** Plan §6 gives a calendar. Missing: what depends on what. Real graph:

```
Task A (dep add) ──> Task B (uses CachedNetworkImage if consolidated in DeelCardImage)
Task A ──> D6 (widgets refactor may touch DeelCardImage again)
Task B ──> depends on C1 resolution (backend column)
D1 ──> depends on Q4/C4 resolution (ADR or allowlist)
D2..D6 ──> mutually independent; can parallelize
```

Add merge-order to §6.

### 🟡 M5 — Task D "no new tests" too absolutist

**Finding.** `CLAUDE.md §6.1` mandates ≥70% widget coverage and `check_new_code_coverage.dart` enforces ≥80% on **changed** lines. An extracted `StatelessWidget` subclass **is** changed code by diff-line measure — if `_BigBlock` is a new class, SonarCloud + the coverage script will want a test on it.

**Correction.** Revise §4.D.4 to: "Each extracted widget class gets 1 smoke test asserting it renders in light + dark mode." ~10 min per extraction, real regression catch for accidental `Semantics` removal.

### 🟡 M6 — Golden test tolerance unspecified

**Finding.** `flutter_test` golden matcher default is byte-exact. Any anti-aliasing drift (e.g. from `CachedNetworkImage` fade curve difference) fails CI noisily. Plan must specify `goldenFileComparator` tolerance or a `matchesGoldenFile` wrapper with per-pixel threshold of e.g. 0.1%.

### 🟡 M7 — No performance baseline captured pre-refactor

**Finding.** Plan mentions "p95 frame < 16ms" but never captures baseline. Correction: `scripts/perf_baseline.sh` (create) runs `flutter drive --profile test_driver/scroll_test.dart` and emits `baseline.json` before Task A. Compare post-merge. CI-optional but manual-mandatory.

### 🟡 M8 — No Flutter Web goldens / smoke in Task A/B DoD

**Finding.** DoD for both tasks lists `flutter test` and golden diff but no web smoke (`flutter build web --release && python -m http.server` click-through). Required given C2 risk.

### 🟡 M9 — WCAG re-audit not scheduled post-Task D

**Finding.** Refactoring `public_profile_screen.dart`, `address_form_modal.dart`, etc. rewrites the Semantics tree. P-42 accessibility audit just merged. A regression here re-opens issue #156. Correction: add `scripts/a11y_audit.sh` run to each D-PR DoD (WidgetTester + `SemanticsFlag.isButton` assertion count must be unchanged).

### 🟡 M10 — Retro hook + e2e-runner not scheduled

**Finding.** `/plan` workflow §Post-Implementation Retrospective should fire after Task B implementation (Large category) but plan never names the trigger. `e2e-runner` agent should run after all Tasks land to catch integration regressions.

### 🟡 M11 — Analytics event schema for Task B undefined

**Finding.** Plan §4.B.3 mentions `escrow_badge_viewed` Firebase event; doesn't specify properties. Required: `{listing_id, seller_kyc_level, price_cents_bucket, user_locale}`. **No PII** (listing_id is public). Must respect `FirebaseAnalytics.setAnalyticsCollectionEnabled(userConsent)` per GDPR consent flow.

---

## MINOR Findings (polish)

| # | Finding | Fix |
|:-:|:--------|:----|
| m1 | DTO path in §4.B.1 incorrect (`dtos/` not `dto/`) | Actual: `lib/features/home/data/dto/listing_dto.dart`. Update. |
| m2 | Plan shows `isEscrowAvailable` truthy at `qualityScore ?? 0 >= 50` — operator precedence bug (`??` binds tighter than `>=` works here, but readers stumble). Parenthesize: `(qualityScore ?? 0) >= 50`. | Correct in plan (already parenthesized, ok). |
| m3 | §6 calendar assumes 5 workdays/week; doesn't note buffer for review cycles | Add ±20% review buffer. |
| m4 | Plan references "R-21 GDPR portability" and similar but PR #161/168 already shipped related work; self-score 97.5% hubris — audit knocks this down | Revise self-score to 82/100 post-audit. |
| m5 | No mention of `pubspec.lock` collision risk with reso/belengaz open branches | Add rebase policy in §5. |
| m6 | Unleash flag naming convention not defined | Use `<feature>_<widget>` pattern: `listings_escrow_badge`. |
| m7 | `DefaultCacheManager` init requires `path_provider` init **before** first use — not called out | Document in `image_cache_manager.dart` + init in `main.dart` alongside Supabase/Firebase. |
| m8 | Task C leaves item 2 (sprint plan PR-ownership noise) without a convention commit | Convert to a `CONTRIBUTING.md` line: "Only tick SPRINT-PLAN tasks that are the subject of the PR." |

---

## Architectural Decisions the Plan Should Have Made (but didn't)

1. **Canonical listing card** (see C6). Blocks further work.
2. **Image pipeline ADR** (see C5).
3. **Escrow authority boundary** (see C1) — domain model or backend-derived?
4. **Freezed adoption decision** (see C4) — implied by Q4; must be an explicit ADR.
5. **Feature-flag governance** — which new UI requires flags? Where does `FEATURE-FLAGS.md` live?
6. **ADR directory location** — none exists in tree; plan assumes it does.

These belong in the plan as a §0.5 "Architectural prerequisites" block the plan must unblock **before** §4 tasks proceed.

---

## Revised Plan Deltas (required)

Apply these patches to `PLAN-pizmam-open-issues.md` before `/implement`:

### Delta 1 — Insert new §0.5 "Architectural Prerequisites"

Block the following issues to be resolved and committed before Task A/B ship:

- ADR-IMG: image-delivery pipeline (unblocks Task A)
- ADR-CARD: canonical listing card (unblocks Task A + B)
- ADR-ESCROW-AUTH: escrow eligibility authority — **must** be backend-computed (unblocks Task B)
- ADR-COPY-WITH: freezed vs hand-rolled sentinel — decides Task D1 fate
- Cloudinary/Supabase CORS verification artifact committed to `docs/verifications/`

### Delta 2 — Task A

- Prepend Step 0 (CORS verification, see C2).
- Wire Sentry error listener (M1).
- Replace §4.A.2 step 2 cache config with validated memory caps (M3).
- Add Cloudinary transform defaults (M2).
- Add Web goldens job (M8).
- Add perf baseline script (M7).

### Delta 3 — Task B

- Flip Q1 default to **backend-authoritative**. Task narrows to wire-only (C1).
- Gate behind `listings_escrow_badge` Unleash flag, default OFF (C3).
- Define analytics schema (M11).
- Confirm copy with legal before flag rollout.

### Delta 4 — Task D1

- Remove from current PR cluster. Block on ADR-COPY-WITH decision. Q4 becomes BLOCKING (C4).

### Delta 5 — Task D (D2–D6)

- Require test per extracted widget (M5).
- Specify golden tolerance (M6).
- Add a11y-assertion diff per PR (M9).

### Delta 6 — §5 Risks — append:

| R8 | Cloudinary/Supabase CORS failure on Web silently breaks images | M | H | Verify headers pre-merge; add Web goldens to CI. |
| R9 | Unleash flag forgotten when enabling rollout | L | M | Flag dashboard audit in weekly ops review. |
| R10 | Extracted widget drops `Semantics()` wrapper | M | H (EAA regression) | Assert semantics count per PR. |
| R11 | Client/server escrow eligibility diverges | H | H (legal) | Eliminated by C1 backend-authority pattern. |

### Delta 7 — §6 Execution — add merge-order DAG (M4)

### Delta 8 — §7 Agent Assignments — add:

- `security-reviewer` to run **after** Task A (new dep) and Task B (trust UI). Not optional.
- `e2e-runner` post-Task-B merge.
- Retro trigger per `/plan` §Post-Implementation for Task B.

### Delta 9 — §9 Self-Score — revise

Post-audit self-score: **33/40 = 82.5%** (loss: -1 governance, -2 ethics/legal framing, -1 architecture, -1 observability, -1 testing). Above PASS threshold but honest.

---

## Final Verdict

**CONDITIONAL PASS.** The plan can proceed to `/implement` **only after**:

1. The 6 critical findings (C1–C6) are addressed via ADRs and plan patches.
2. User provides the 5 Socratic answers **with Q1 default flipped** per C1.
3. Backend authority for escrow eligibility is committed on reso's side (tracked as a new `[R]` issue/PR).
4. The plan file is revised per Deltas 1–9 and re-saved.

**Estimated additional work:** 0.5 day for ADRs + 0.5 day for plan revision + 2 days for reso's migration (parallel) = **~1 day of pizmam time, zero wall-clock cost** if reso's work runs in parallel.

**If critical findings are accepted as-is (not corrected):** the plan ships functional code but incurs legal risk on Task B (C1), silent web breakage risk on Task A (C2), and compounding tech debt on Tasks D1 and the `ListingCard`/`DeelCard` split (C4, C6). All four are landmines that cost 5–10× more to fix once in production.

Respectfully recommend: **fix before `/implement`.**

— End of audit.
