# PLAN-P56 — Firebase Performance custom traces with provisional p95 SLOs

> **Owner:** 🔵 pizmam (`@emredursun`) · with **co-reviewer requirement** from 🟢 belengaz (SLO + observability scope)
> **Branch:** `feature/pizmam-audit-quickwins-P56-P57-P58` (shared)
> **Severity / Audit ref:** P2 / `H5` (preflight, Hi-severity launch-supporting) · `P-56` (retrospective)
> **Effort:** S–M — 1 to 2 days (originally estimated S; specialist synthesis revised to S–M)
> **Workflow:** `/plan` v2.2.0 + `/quality-gate` v2.1.0 + Specialist Synthesis Protocol
> **Task size:** **Medium** (~8–10 files; introduces a new architectural seam)
> **Created:** 2026-04-25 · Status: ⏳ Awaiting approval

---

## 1. Context (the "why")

`firebase_performance ^0.11.2` is in `pubspec.yaml`. `firebasePerformanceProvider` already exists in `lib/core/services/firebase_service.dart:65–68`. **Zero custom traces are defined.** The SDK ships, initialises, and produces only auto-instrumented network/screen metrics — *no business-meaningful instrumentation*.

This is identified by the audit as preflight finding **H5** (Observability D10 = 6/10) and retrospective task **P-56**. It is **launch-supporting**, not launch-blocking — but Apple App Store review and Google Vitals weight startup-time and interaction-latency heavily, and operating without published p95 SLOs means we cannot defend a regression conversation post-launch.

The architect specialist also identified a **double-instrumentation risk**: Sentry currently traces all platforms at 0.2 sample rate. After P-56, this is wasted budget on mobile (Firebase covers it better) and should be narrowed to web-only.

### Audit reference

- `docs/audits/2026-04-25-tier1-retrospective.md#p-56`
- `docs/audits/2026-04-25-tier1-preflight.md` finding `H5`

---

## 2. Decisions Required (Socratic gate, pre-answered with specialist input)

| # | Question | Decision | Rationale (cite specialist where applicable) |
|---|----------|----------|---|
| **D1** | Where in Clean Architecture does the trace seam live? | **`core/services/performance/` facade exposed via Riverpod**, consumed from data layer (repos) for I/O traces and presentation layer for render traces | Architect: matches existing `sentry_service.dart` / `firebase_service.dart` shape; honors §1.2 layer rules. Reject: domain interceptors (cross-cutting coupling), provider observers (no method-level boundaries), presentation mixins (cannot trace pre-paint data fetches). |
| **D2** | Web platform strategy? | **Adapter abstraction + Sentry transaction fallback on web** (option (b)) | Architect: `firebase_performance` web `Trace` API has parity gaps; Sentry already initialised on web at 0.2 sample. One interface, two implementations selected at composition time. |
| **D3** | Trace name list (v1) | **5 traces:** `app_start`, `listing_load`, `search_query`, `payment_create`, `image_load`. Optional v2 (next sprint): `chat_open`, `kyc_step`, `escrow_release`. | These cover the 5 user-perceived hotspots and align with the audit's H5 acceptance criteria. |
| **D4** | Attribute privacy model | **Allowlist** the safe attributes; **forbid** PII. (See §3 Architecture Notes for explicit table.) | Architect: Firebase Performance attributes export to BigQuery as plaintext queryable surface — GDPR threat model requires bucketing high-cardinality fields. |
| **D5** | Trace boundaries (e.g. `listing_load`) | **Start** at use-case invocation, **stop** at first frame containing hero image + price + seller row. Sub-metric `gallery_loaded_ms` for deferred image work. | Architect: aligns with marketplace UX research on perceived load; documented convention in trace registry to prevent boundary drift. |
| **D6** | Sampling | **Production: 100%** (Firebase free quota auto-throttles to ~10K events/app/day). **Staging: 100%.** **Debug: disabled** via `setPerformanceCollectionEnabled(false)` (mirrors Crashlytics §pattern). Add Remote Config flag `perf_trace_sample_rate` for runtime override. | Architect: down-sampling pre-launch hurts baseline statistics. Remote Config flag is the post-launch safety valve. |
| **D7** | Riverpod integration | **`@Riverpod(keepAlive: true)`** singleton facade `performanceTracerProvider`. Test seam via `ProviderScope.overrides` with `FakePerformanceTracer`. | TDD-guide: trace state is process-global; per-route scoping leaks on rebuild. Mandatory interface seam — real `Trace` cannot be instantiated outside SDK. |
| **D8** | SLO baseline strategy | **Two-phase commitment.** Phase 1 (this PR): provisional p95 from industry priors. Phase 2 (T+14 days): replace with measured p95 via ADR amendment. | Architect: deferring all numbers misses the audit gate; Google RAIL + Web Vitals + Firebase median e-commerce data ground Phase 1 numbers. Alert at p95×1.5 for first 14 days to dampen false positives. |
| **D9** | Mocking strategy | **Inject `PerformanceTracer` interface; mock the interface (option (b)).** `FakePerformanceTracer` records calls into a list for assertions. | TDD-guide: mocking SDK directly couples to API surface; `useEmulator` does not exist for Performance Monitoring. |
| **D10** | SLO regression test in unit/widget tests? | **No — anti-pattern.** SLO enforcement belongs in staging via Firebase Performance alerting + (later) Lighthouse CI. | TDD-guide: wall-clock under `flutter test` is dominated by VM warmup; flaky enforcement is worse than absent. |
| **D11** | Sentry mobile transactions after P-56 lands? | **Disable** — set `tracesSampleRate = 0` on mobile platforms in `sentry_service.dart`. Keep Sentry SDK initialised for errors. | Architect: post-P-56 mobile transactions duplicate Firebase coverage at Sentry-quota cost. One-line flip if reverted. |
| **D12** | New ADR? | **Yes — ADR-027** ("Performance instrumentation: Firebase Performance on mobile, Sentry on web") | Tier-1 standard: a new architectural seam + cross-cutting privacy decision (attribute allowlist) deserves an ADR. ADR-002 / ADR-022 precedent established. |
| **D13** | Lint guard for direct SDK imports? | **Yes** — extend `scripts/check_quality.dart` to fail on direct `firebase_performance` imports outside `lib/core/services/performance/`. | TDD-guide: prevents the seam from leaking, mandatory in v1 because the seam is brand-new. |

---

## 3. Architecture Notes

### 3.1 New module layout

```
lib/core/services/performance/
├── performance_tracer.dart            # interface — contract only (≤80 LOC)
├── trace_attributes.dart               # attribute allowlist + bucketing helpers (≤80 LOC)
├── trace_names.dart                    # const trace name registry (≤30 LOC)
├── firebase_performance_tracer.dart    # mobile impl (≤120 LOC)
├── sentry_performance_tracer.dart      # web impl (≤100 LOC)
├── noop_performance_tracer.dart        # default for tests (≤40 LOC)
└── performance_tracer_provider.dart    # @Riverpod facade (≤60 LOC)
```

All files under §2.1 file-length budget for utilities (100 lines). The provider file is the only cross-cutting one and stays under 60 LOC.

### 3.2 Interface (conceptual; no code in this plan)

```
abstract interface class PerformanceTracer {
  /// Returns an opaque handle that callers must `stop()`.
  PerformanceTraceHandle start(String name);
}
abstract interface class PerformanceTraceHandle {
  void putAttribute(String key, String value);   // allowlist enforced
  void putMetric(String key, int value);
  Future<void> stop();
}
```

### 3.3 Trace registry (`trace_names.dart`)

```
const traceAppStart      = 'app_start';
const traceListingLoad   = 'listing_load';
const traceSearchQuery   = 'search_query';
const tracePaymentCreate = 'payment_create';
const traceImageLoad     = 'image_load';
```

### 3.4 Attribute privacy model (D4)

| Attribute | Status | Bucketing? | Reason |
|-----------|--------|-----------|--------|
| `locale` | ✅ allow | none | low cardinality (NL/EN) |
| `platform` | ✅ allow | none | low cardinality (iOS/Android/Web) |
| `network_type` | ✅ allow | none | wifi/cellular/none |
| `cache_hit` | ✅ allow | none | bool |
| `result_count` | ✅ allow | **yes** — bucket `0` / `1-10` / `11-50` / `50+` | high cardinality |
| `image_size_bucket` | ✅ allow | yes — `<200kb` / `200-1mb` / `>1mb` | infrastructure metric |
| `payment_method` | ✅ allow | none | iDEAL / card / future |
| `listing_category` | ✅ allow | none | low cardinality |
| `listing_price_bucket` | ✅ allow | yes — `0-50` / `50-200` / `200-1000` / `1000+` EUR | high cardinality |
| `user_id` | ❌ forbid | — | PII — re-identification risk |
| `email` | ❌ forbid | — | PII |
| `listing_id` | ❌ forbid | — | joined with timestamp + IP → re-identifies viewers of niche listings |
| `search_term` | ❌ forbid | — | free-text PII surface |
| `coordinates` / `lat` / `lon` | ❌ forbid | — | PII (location) |
| `device_id` / `ip` | ❌ forbid | — | PII |

Enforcement: `TraceAttributes.put()` validates against the allowlist at runtime; debug builds throw, release builds log to Sentry breadcrumbs and silently drop.

### 3.5 Trace boundary conventions (D5)

| Trace | Start | Stop | Sub-metrics |
|-------|-------|------|-------------|
| `app_start` | `main()` first line after `await initSentry()` — must follow Sentry init so `SentryPerformanceTracer` attaches to a real hub instead of pre-init `NoOpHub` (PR #247). `initSentry()` cost (~100–200 ms) is therefore excluded from the trace; calibrate the p95 ≤ 2.5 s SLO accordingly. | `WidgetsBinding.addPostFrameCallback` after first frame of root navigator | `splash_to_first_frame_ms`, `dependencies_init_ms` |
| `listing_load` | `GetListingDetailUseCase.execute()` invocation | `addPostFrameCallback` after `AsyncData` first paint with hero image visible | `gallery_loaded_ms`, `seller_loaded_ms` |
| `search_query` | First post-debounce committed query (not per keystroke) | first row visible in `SearchResultsView` | `result_count_bucket` |
| `payment_create` | `CreatePaymentUseCase.execute()` invocation | Mollie WebView load complete OR error | `mollie_response_ms` |
| `image_load` | `cached_network_image` fetch start | decode-success or decode-error | `cache_hit`, `image_size_bucket` |

### 3.6 Provisional p95 SLOs (D8 Phase 1)

| Trace | p95 SLO | Source |
|-------|---------|--------|
| `app_start` | ≤ **2.5s** | Google RAIL + LCP guidance |
| `listing_load` | ≤ **1.5s** | Firebase median e-commerce listing-load benchmark |
| `search_query` | ≤ **800ms** | Google RAIL response |
| `payment_create` | ≤ **3.0s** | Mollie published p95 + safety margin |
| `image_load` | ≤ **1.2s** | LCP P75 budget for hero image |

**Alert thresholds (first 14 days):** p95 × 1.5 (e.g. `app_start` alerts at >3.75s) — visibility without paging. Promote to p95 × 1.0 after baseline phase.

### 3.7 Web fallback architecture (D2)

```
PerformanceTracer (interface)
    ├── FirebasePerformanceTracer    (mobile — kIsWeb == false)
    ├── SentryPerformanceTracer       (web — kIsWeb == true)
    └── NoopPerformanceTracer         (tests via ProviderScope override)
```

The provider returns the right implementation at composition time:

```
if (kIsWeb)         → SentryPerformanceTracer
else if (kDebugMode) → NoopPerformanceTracer
else                → FirebasePerformanceTracer
```

Identical trace names + attribute keys across both backends so SLO reports normalise downstream.

### 3.8 Sentry mobile transactions disabled (D11)

In `sentry_service.dart`:

```
options.tracesSampleRate = kIsWeb ? 0.2 : 0.0;
```

Keeps Sentry SDK initialised everywhere (errors stay on); only mobile transactions are dropped.

---

## 4. Mandatory Rule Consultation

| Rule | Applicable? | How addressed |
|------|-------------|---------------|
| §1.2 Layer dependency | **Yes** | Interface in `core/services/`; data-layer repos depend on interface; domain remains pure Dart |
| §2.1 File length | **Yes** | All new files ≤120 LOC; no §2.1 exemption needed |
| §3.3 No duplication | **Yes** | All trace names from `trace_names.dart` constants — never inline string literals |
| §6.1 Coverage | **Yes** | New code requires ≥80% (pre-push). 100% on the `payment_create` trace integration (CLAUDE.md §6.1 payment-path rule) |
| §6.3 Test layer matrix | **Yes** | Repository tests mock the tracer; ViewModel tests assert lifecycle; widget tests for `app_start` and `image_load` |
| §8 Quality Gates | **Yes** | New script lint guard added |
| §9 Supabase rules | No (no DB change) | — |
| §10 Accessibility | Indirect | Performance instrumentation has no a11y surface; `MediaQuery.disableAnimations` does not affect trace boundaries |

### `/quality-gate` Ethics & Safety Pass

| Domain | Result |
|--------|--------|
| **AI Bias** | N/A — no algorithmic decision; descriptive instrumentation only |
| **GDPR / Privacy** | ✅ **Allowlist + bucketing model** designed for data minimisation. Forbid list explicitly excludes PII. ARTICLE 5(1)(c) compliant. |
| **Automation Safety** | ⚠️ Risk: silent SDK init failure in production → no traces collected. Mitigation: `firebase_performance` init failure logged to Sentry as breadcrumb (not user-visible). |
| **User Autonomy** | N/A — no UI |
| **Human-in-the-Loop** | N/A — descriptive only, no automated decisions trigger off traces |

**Ethics verdict: ✅ APPROVED.** No rejection trigger fires.

### Competitive market reference (per `/quality-gate` Step 1)

| Competitor | Approach | Insight |
|------------|----------|---------|
| Vinted | Firebase Performance + DataDog RUM | Same dual-stack pattern (Firebase mobile + RUM web) — validates D2 |
| Stripe | OpenTelemetry + custom dashboards | Higher-tier; out of v1 scope but ADR-027 should note migration path |
| Wallapop | Firebase Performance only | Single-stack — confirmed loss of web telemetry |
| Marktplaats | New Relic | Rejected for cost on free-tier marketplace |
| Linear | Datadog + custom RUM | Reference for premium UX expectation but architecture dwarfs DeelMarkt scale |

**Differentiation:** DeelMarkt's bucketed-attribute model (§3.4) is stricter than Vinted's published practice — explicit GDPR-first allowlist is a meaningful product-trust signal in the ACM-supervised Dutch marketplace context.

---

## 5. Implementation Tasks (with verification criteria)

### Phase A — Architecture seam (Day 1 morning)

| # | Task | File(s) | Verification |
|---|------|---------|--------------|
| A1 | Write ADR-027 documenting decisions D1–D13 | `docs/adr/ADR-027-performance-instrumentation.md` | Reviewed by belengaz + reso; status: Proposed |
| A2 | Create `trace_names.dart` constants | `lib/core/services/performance/trace_names.dart` | 5 const strings; ≤30 LOC |
| A3 | Create `trace_attributes.dart` allowlist + bucketing helpers | `lib/core/services/performance/trace_attributes.dart` | Allowlist enum; `bucketResultCount()`, `bucketImageSize()`, `bucketPriceCents()` helpers; ≤80 LOC |
| A4 | Define `PerformanceTracer` interface + `PerformanceTraceHandle` | `lib/core/services/performance/performance_tracer.dart` | Pure Dart interface; no Firebase imports; ≤80 LOC |
| A5 | Implement `FirebasePerformanceTracer` (mobile) | `lib/core/services/performance/firebase_performance_tracer.dart` | Wraps `FirebasePerformance.instance`; respects allowlist; ≤120 LOC |
| A6 | Implement `SentryPerformanceTracer` (web) | `lib/core/services/performance/sentry_performance_tracer.dart` | Maps trace name → Sentry transaction; ≤100 LOC |
| A7 | Implement `NoopPerformanceTracer` (tests) | `lib/core/services/performance/noop_performance_tracer.dart` | All methods no-op; records call list for `Fake*` test double; ≤40 LOC |
| A8 | Create `performanceTracerProvider` Riverpod facade | `lib/core/services/performance/performance_tracer_provider.dart` | `@Riverpod(keepAlive: true)`; selects impl by `kIsWeb` + `kDebugMode`; ≤60 LOC |

### Phase B — Wiring + boundary instrumentation (Day 1 afternoon)

| # | Task | File(s) | Verification |
|---|------|---------|--------------|
| B1 | Configure Performance collection on init | `lib/core/services/firebase_service.dart` | Add `setPerformanceCollectionEnabled(!kDebugMode)` call mirroring Crashlytics pattern |
| B2 | Disable Sentry mobile transactions | `lib/core/services/sentry_service.dart` | `tracesSampleRate = kIsWeb ? 0.2 : 0.0` |
| B3 | Wire `app_start` trace | `lib/main.dart` | Start at first line after `await initSentry()` (so `SentryPerformanceTracer` attaches to a real hub, not pre-init `NoOpHub` — PR #247); stop in `addPostFrameCallback` |
| B4 | Wire `listing_load` trace | `lib/features/listing_detail/data/...repository.dart` + viewmodel | Start at use-case; stop on first paint |
| B5 | Wire `search_query` trace | `lib/features/search/.../search_viewmodel.dart` | Start on debounced commit; stop on first result row paint |
| B6 | Wire `payment_create` trace | `lib/features/transaction/.../create_payment_use_case.dart` | Start at execute; stop at Mollie WebView load complete |
| B7 | Wire `image_load` trace | `lib/widgets/cards/deel_card_image.dart` + `lib/widgets/media/image_gallery_page.dart` | Wraps `cached_network_image` builders |
| B8 | Add Remote Config flag `perf_trace_sample_rate` (default 1.0) | `lib/core/services/firebase_service.dart` (Remote Config defaults) | Reads override at runtime; default 1.0 |
| B9 | Add lint guard | `scripts/check_quality.dart` | Fails on `import 'package:firebase_performance/...'` outside `lib/core/services/performance/` |

### Phase C — Tests (Day 2 morning)

| # | Task | File(s) | Verification |
|---|------|---------|--------------|
| C1 | `FakePerformanceTracer` test double recording calls | `test/_helpers/fake_performance_tracer.dart` | Public `recordedCalls` list; ≤80 LOC |
| C2 | Unit test for `trace_attributes.dart` (allowlist + bucketing) | `test/core/services/performance/trace_attributes_test.dart` | 100% coverage; PII keys throw in debug |
| C3 | Unit test for `performance_tracer_provider.dart` (impl selection) | `test/core/services/performance/performance_tracer_provider_test.dart` | Asserts correct impl per `kIsWeb`/`kDebugMode` |
| C4 | Lifecycle / leak contract test (`tracerContract`) | `test/_helpers/tracer_contract.dart` | Reusable: success / throw / cancel paths each end with `activeTraceCount == 0` |
| C5 | Apply contract test to all 5 trace integrations | individual viewmodel/repo tests | Use existing test files; add the assertion via contract helper |
| C6 | `app_start` widget test with `FakeAsync` | `test/main_app_start_trace_test.dart` | Asserts trace start before first frame, stop after |
| C7 | `image_load` widget test with `mocktail_image_network` | `test/widgets/cards/deel_card_image_test.dart` | Asserts trace stops on success and decode-error |
| C8 | Lint guard test | `test/scripts/check_quality_perf_lint_test.dart` | Asserts script flags forbidden imports |

### Phase D — Documentation (Day 2 afternoon)

| # | Task | File(s) | Verification |
|---|------|---------|--------------|
| D1 | Author SLO doc | `docs/observability/perf-slos.md` | Includes provisional p95 + Phase 2 commitment |
| D2 | Author trace registry doc | `docs/observability/trace-registry.md` | Per-trace: name, boundary convention, attributes, owner |
| D3 | Update CLAUDE.md §10 reference | `CLAUDE.md` | Add link to `docs/observability/` |
| D4 | Update CHANGELOG | `docs/CHANGELOG.md` | Unreleased section: "feat(observability): introduce Firebase Performance custom traces with provisional p95 SLOs (closes P-56 / H5)" |
| D5 | Update SCREENS-INVENTORY observability appendix (if landed after P-57) | `docs/SCREENS-INVENTORY.md` | Cross-link traces ↔ screens |

**Estimated total:** 1.5–2 days end-to-end (including lint guard + tests).

---

## 6. Cross-cutting Concerns

### Security / Privacy
- ✅ Allowlist + bucketing model in §3.4 is the privacy primitive
- ✅ Forbid list excludes all PII; runtime enforcement throws in debug, drops in release
- ✅ Sentry breadcrumbs (PII-aware, scrubbed) used for ad-hoc debugging instead of attributes
- ✅ Remote Config kill switch (`perf_trace_sample_rate = 0.0`) for emergency disable

### Testing
- TDD-guide synthesis applied: interface seam mandatory; SDK-direct mocks anti-pattern; contract test reused across all 5 integrations; SLO timing not enforced in unit tests
- New code coverage target: ≥80% (CI floor); `payment_create` integration: 100% (CLAUDE.md §6.1)
- Lint guard test ensures the seam doesn't leak

### Documentation
- ADR-027 (mandatory — new architectural seam)
- `docs/observability/perf-slos.md` (mandatory — SLO commitment)
- `docs/observability/trace-registry.md` (mandatory — boundary conventions)
- CHANGELOG entry

### Accessibility
- No a11y surface; `MediaQuery.disableAnimations` does not affect trace boundaries (instrumentation is observability, not animation)

### Localisation
- `locale` is a trace attribute (NL/EN) — informational only

### Performance
- TraceTracer overhead: SDK calls are ~microseconds; negligible. Lint test asserts no allocation in noop path.
- Test suite cost: noop default + interface seam → no measurable CI slowdown

### Observability
- This **is** the observability layer
- Cross-references existing Sentry, Crashlytics, Analytics; ADR-027 documents the strict separation of duties (Architect §8)

---

## 7. Risk Matrix

| ID | Risk | Likelihood | Impact | Mitigation |
|----|------|-----------|--------|-----------|
| **R1** | Web `firebase_performance` parity gap blocks Sentry-fallback strategy | Low | High | Adapter abstraction (D2) isolates the risk; if Sentry can't carry web traces, fall back to manual `print` + Datadog browser RUM (separate ADR amendment). |
| **R2** | Allowlist enforcement throws break production via accidentally added forbid attribute | Medium | Medium | Debug throws / release drops; CI lint guard fails on direct SDK import (catches new attribute additions outside the central registry). |
| **R3** | Boundary conventions drift across ViewModels (e.g. one ends at "AsyncData", another at "first frame") | Medium | Medium | Trace registry doc (D2) is authoritative; PR review enforces consistency. |
| **R4** | Sentry mobile-transactions disable removes a future fallback if Firebase Perf is later deprecated | Low | Medium | One-line revert; ADR-027 explicitly tracks this. |
| **R5** | Provisional p95 numbers wrong → false alerts | Medium | Low | Phase-1 alert threshold = p95×1.5 absorbs noise; Phase 2 (T+14d) replaces with measured values. |
| **R6** | Riverpod `keepAlive` singleton holds traces across hot-reload during dev | Low | Low | NoopPerformanceTracer in debug mode (D6) means no SDK state to leak in dev. |
| **R7** | Free-tier Firebase quota exceeded post-launch | Low | Medium | Remote Config flag `perf_trace_sample_rate` flips down without redeploy. |
| **R8** | `mocktail_image_network` not present in dev_dependencies → C7 blocked | Low | Low | Add to dev_dependencies in this PR; existing image tests already use a similar pattern. |
| **R9** | ADR-027 review delay blocks merge | Medium | Low | ADR ships as "Proposed"; merge unblocked; "Accepted" in follow-up. Mirrors ADR-022/023 pattern. |
| **R10** | Lint guard script breaks build_runner / generated `.g.dart` files | Low | Medium | Lint scope: Dart files outside `**/*.g.dart`. Verified in C8. |

---

## 8. Rollback Plan

### Levels of rollback

| Level | Action | Effect |
|-------|--------|--------|
| **L1 — Disable collection** | Remote Config: set `perf_trace_sample_rate = 0.0` | All traces drop. No redeploy. |
| **L2 — Single-trace disable** | Code: short-circuit a specific `start()` call site | Targeted revert, e.g. only `payment_create` |
| **L3 — Disable Performance entirely** | `firebase_service.dart`: `setPerformanceCollectionEnabled(false)` | Hot-fix release; SDK still initialised |
| **L4 — Full revert** | `git revert` of merge commit | Cleanest; restores `firebasePerformanceProvider` to unused state |
| **L5 — Restore Sentry mobile transactions** | One-line: `tracesSampleRate = 0.2` (drop the `kIsWeb` guard) | Independent of L1–L4 |

**Rollback eligibility:** all 5 levels independent; data loss = none (analytics events not user-visible state).

---

## 9. Quality Gate Checklist (pre-merge)

| Gate | Owner | Evidence |
|------|-------|---------|
| ADR-027 written and stored under `docs/adr/` | pizmam | File present |
| `docs/observability/perf-slos.md` + `trace-registry.md` present | pizmam | Files present |
| `flutter analyze --fatal-infos` clean | pizmam | CI |
| `flutter test` green; coverage ≥80% on changed files | pizmam | CI |
| Payment-path coverage 100% (`create_payment_use_case`) | pizmam | CLAUDE.md §6.1 |
| `dart run scripts/check_quality.dart --all` zero violations | pizmam | CI |
| Lint guard rejects direct SDK imports outside `core/services/performance/` | pizmam | C8 test |
| OSV-Scanner / Trivy / TruffleHog clean | CI | `security` job |
| SonarCloud quality gate | CI | `sast` job |
| Reviewer approval (architecture + observability scope) | belengaz (mandatory) + reso (architecture) | GitHub PR |
| Visual smoke: golden tests still pass (no UI change expected) | pizmam | CI screenshots |

---

## 10. Acceptance Criteria (for PR description)

- [ ] ADR-027 created under `docs/adr/`, status: Proposed
- [ ] 8 new files under `lib/core/services/performance/` (interface, 3 impls, registry, attributes, provider, hot-path helpers); each ≤§2.1 budget
- [ ] 5 trace integrations live: `app_start`, `listing_load`, `search_query`, `payment_create`, `image_load`
- [ ] Sentry mobile `tracesSampleRate = 0` (D11)
- [ ] Remote Config flag `perf_trace_sample_rate` defaulted to 1.0
- [ ] Lint guard active in `scripts/check_quality.dart`
- [ ] `FakePerformanceTracer` + `tracerContract` test helper present
- [ ] 5 contract-test integrations green (one per trace)
- [ ] Privacy: allowlist enforced; PII keys throw in debug; Sentry breadcrumb fallback
- [ ] `docs/observability/perf-slos.md` published with Phase 1 numbers + Phase 2 commitment
- [ ] `docs/observability/trace-registry.md` published with per-trace conventions
- [ ] CLAUDE.md §10 references new docs
- [ ] CHANGELOG updated
- [ ] CI green (all 6 workflows)
- [ ] Closes preflight finding `H5`; closes retrospective task `P-56`

---

## 11. Sequencing Note

P-56 should land **last** in the `feature/pizmam-audit-quickwins-P56-P57-P58` branch (after P-58 and P-57). Reasoning:

1. P-58 first → mechanical lockfile change, isolates regressions
2. P-57 second → doc-only churn; reviewer can focus on accuracy
3. P-56 last → architectural change; reviewers can focus on the seam without other noise

**If branch grows too large for a single PR:** split into:
- PR 1: P-58 + P-57 (quick wins)
- PR 2: P-56 (architecture-only)

Decision deferred to PR-time based on diff size.

---

## 12. Provenance

- **Workflow:** `.agent/workflows/plan.md` v2.2.0 (Medium track) + `/quality-gate` v2.1.0 (full Ethics & Safety pass — ✅ APPROVED) + Specialist Synthesis Protocol
- **Specialist input received:**
  - **Architect** — integration pattern, web fallback, attribute privacy model, trace boundaries, sampling, Riverpod integration, SLO strategy, observability stack interaction
  - **TDD-guide** — testable boundary, mocking strategy, per-trace test types, lifecycle leak detection, SLO regression anti-pattern, CI cost, Riverpod test integration, anti-pattern list
- **Audit cross-references:** `docs/audits/2026-04-25-tier1-retrospective.md#p-56`, `docs/audits/2026-04-25-tier1-preflight.md` finding `H5`
- **Rule bases:** CLAUDE.md §1.2 / §2.1 / §3.3 / §6.1 / §6.3 / §8 / §10; ADR-002 / ADR-022 (precedent for cross-cutting decisions); existing `firebase_service.dart` and `sentry_service.dart` patterns
- **Differentiation evidence:** competitor matrix (Vinted / Stripe / Wallapop / Marktplaats / Linear) — DeelMarkt's GDPR-first attribute allowlist exceeds Vinted's published practice
