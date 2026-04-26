# ADR-027: Performance instrumentation — Firebase Performance on mobile, Sentry on web

### Status

**Accepted** — 2026-04-25 · Author: pizmam · Reviewers: belengaz (observability scope, architecture seam — approved post-Phase A in PR #220 review), reso (architecture seam — implicit via no objection on `lib/core/services/performance/` layer placement)

Phase A (this PR, #220) shipped the seam, ADR commits, attribute allowlist, dual-backend implementations, Sentry mobile sample = 0, and provisional p95 SLOs. Phase B (#221), lint guard (#222), and Phase 2 measurement (#223) tracked as follow-up issues.

### Context

`firebase_performance ^0.11.2` was added to `pubspec.yaml` in Sprint 1 as part of E07 infrastructure setup. The SDK ships, initialises, and produces only auto-instrumented network/screen metrics — **no business-meaningful instrumentation**. Audit `2026-04-25-tier1-preflight.md` flagged this as **H5**:

> "Firebase Performance SDK present with 0 custom traces"

Operating without published p95 SLOs means we cannot defend a regression conversation post-launch and Apple App Store review / Google Vitals weight startup-time and interaction-latency heavily.

Concurrently, `sentry_flutter ^9.0.0` was already initialised at `tracesSampleRate = 0.2` on **all** platforms. After P-56 lands custom Firebase Performance traces, mobile Sentry transactions become a **double instrumentation** at Sentry-quota cost. The architecture must converge.

### Decision

Adopt a **dual-backend instrumentation strategy** with a unified `PerformanceTracer` Dart interface:

1. **Mobile (iOS + Android, release builds):** `FirebasePerformance` custom traces via `FirebasePerformanceTracer`.
2. **Web (release builds):** Sentry transactions via `SentryPerformanceTracer` (Firebase Performance web has parity gaps for the custom-trace API).
3. **Debug builds + tests:** `NoopPerformanceTracer` (zero overhead, deterministic).
4. **Composition** via `performanceTracerProvider` (`@Riverpod(keepAlive: true)`) at `lib/core/services/performance/`.
5. **Sentry mobile transactions disabled:** `tracesSampleRate = kIsWeb ? 0.2 : 0.0`. Sentry SDK stays initialised everywhere for error tracking; only mobile transactions are dropped.
6. **Privacy:** strict attribute allowlist (`TraceAttributes`); high-cardinality values bucketed; PII forbidden (`user_id`, `email`, `listing_id`, `search_term`, `coordinates`, `device_id`, `ip`).
7. **SLO commitment:** two-phase. Phase 1 (this PR) — provisional p95 from industry priors. Phase 2 (T+14 days) — measured p95 via ADR amendment.
8. **Sampling:** production 100% (Firebase free quota auto-throttles); debug disabled via `setPerformanceCollectionEnabled(false)`. Remote Config flag `perf_trace_sample_rate` (default 1.0) is the post-launch safety valve.
9. **Lint guard:** `scripts/check_quality.dart` will reject direct `firebase_performance` imports outside `lib/core/services/performance/`. Ensures the seam does not leak.

### Trace registry (v1)

| Name | Boundary | Phase 1 p95 SLO |
|------|----------|-----------------|
| `app_start` | `WidgetsFlutterBinding.ensureInitialized()` → first frame of root navigator | ≤ **2.5s** |
| `listing_load` | `GetListingDetailUseCase.execute()` → first paint with hero image + price + seller row | ≤ **1.5s** |
| `search_query` | First post-debounce committed query → first row visible | ≤ **800ms** |
| `payment_create` | `CreatePaymentUseCase.execute()` → Mollie WebView load complete (or error) | ≤ **3.0s** |
| `image_load` | `cached_network_image` fetch start → decode-success or decode-error | ≤ **1.2s** |

Phase 1 alert threshold = p95 × 1.5 (visibility without paging) for the first 14 days.

### Consequences

#### Positive
- Single source of truth for latency telemetry per platform.
- Privacy-by-design: attribute allowlist enforced at compile-test boundary; debug builds throw on forbidden keys, release builds silently drop.
- Sentry mobile-quota saved for what it does best (web transactions + error context everywhere).
- Test seam is mandatory and standard (`PerformanceTracer` interface) — no SDK shape coupling in tests.
- ADR-022 image-cache observability gains a quantitative complement (`image_load` SLO).

#### Negative
- Two backends → two dashboards. Mitigated by identical trace names + attribute keys across backends so SLO reports normalise downstream.
- Sentry mobile transactions disabled — loses one fallback if Firebase Performance is later deprecated. One-line revert (`tracesSampleRate` flag) tracked in this ADR.
- Provisional p95 numbers may be wrong for first 14 days. Mitigation: alert at p95 × 1.5; replace with measured values via ADR amendment.

#### Operational
- `setPerformanceCollectionEnabled(!kDebugMode)` mirrors the existing Crashlytics pattern.
- Web users still get latency telemetry via Sentry transactions (no regression vs status quo).

### Alternatives Considered

1. **Firebase Performance everywhere** — rejected: web custom-trace parity gap; would silently lose web latency signal.
2. **Sentry transactions everywhere** — rejected: Sentry quota cost; less granular control vs Firebase Performance auto-instrumentation; Sentry transactions are a coarser tool.
3. **OpenTelemetry + custom backend** — rejected for v1: dwarf project scale; revisit at growth tier (>10K MAU).
4. **Cross-cutting interceptor at use-case layer** — rejected: forces every use case to know about telemetry; high coupling.
5. **Riverpod `ProviderObserver`** — rejected: only sees provider lifecycle events; cannot mark sub-stages or trace pre-paint data fetches.
6. **Presentation-level mixin on screens** — rejected: cannot trace pure data fetches that happen before a screen builds (cold start, prefetch).

### Rollback

Five independent levels (single-line / single-commit each):

| Level | Action | Effect |
|-------|--------|--------|
| **L1** | Remote Config: `perf_trace_sample_rate = 0.0` | All traces drop. No redeploy. |
| **L2** | Code: short-circuit a specific `start()` call site | Targeted revert |
| **L3** | `setPerformanceCollectionEnabled(false)` | Hot-fix release; SDK still initialised |
| **L4** | `git revert` of the introducing merge commit | Restores `firebasePerformanceProvider` to unused state |
| **L5** | Restore Sentry mobile transactions | One-line: drop the `kIsWeb` guard in `sentry_service.dart` |

Data loss = none (analytics events not user-visible state).

### Related

- **Plan:** `docs/PLAN-P56-firebase-performance-traces.md`
- **Audit refs:** `docs/audits/2026-04-25-tier1-preflight.md` (H5), `docs/audits/2026-04-25-tier1-retrospective.md` (P-56)
- **Observability docs:** `docs/observability/perf-slos.md`, `docs/observability/trace-registry.md`
- **Companion ADRs:** ADR-022 (image delivery — read-path counterpart), ADR-019 (PWA strategy — web context)
- **Implementing files:** `lib/core/services/performance/{performance_tracer.dart, firebase_performance_tracer.dart, sentry_performance_tracer.dart, noop_performance_tracer.dart, trace_names.dart, trace_attributes.dart, performance_tracer_provider.dart}`
