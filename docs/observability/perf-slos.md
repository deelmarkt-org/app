# DeelMarkt — Performance SLO Commitments

> **Phase 1 (Provisional)** — published 2026-04-25 with PR for P-56
> **Phase 2 (Measured)** — scheduled 2026-05-09 (T+14 days post-launch of P-56)
> Source of truth: ADR-027 + `lib/core/services/performance/trace_names.dart`

## SLO Table

| Trace | Phase 1 p95 SLO | Phase 1 alert threshold | Source | Phase 2 status |
|-------|-----------------|-------------------------|--------|----------------|
| `app_start` | ≤ 2.5 s | 3.75 s (×1.5) | Google RAIL + LCP guidance | TBD — measure post-launch |
| `listing_load` | ≤ 1.5 s | 2.25 s (×1.5) | Firebase median e-commerce listing-load benchmark | TBD |
| `search_query` | ≤ 800 ms | 1.2 s (×1.5) | Google RAIL response budget | TBD |
| `payment_create` | ≤ 3.0 s | 4.5 s (×1.5) | Mollie published p95 + safety margin | TBD |
| `image_load` | ≤ 1.2 s | 1.8 s (×1.5) | LCP P75 budget for hero image | TBD |

## Methodology

### Phase 1 — Provisional (this PR)

Published numbers are **opinionated priors**, not measurements. They are grounded in:

- **Google RAIL model** (Response 100 ms, Animation 16 ms, Idle 50 ms, Load 1 s)
- **Core Web Vitals LCP** (P75 ≤ 2.5 s for "Good" rating)
- **Firebase Performance benchmarks** (e-commerce listing-load median ≈ 1.4 s)
- **Mollie API published latency** (p95 < 2 s + 1 s WebView load buffer)

**Alert thresholds = p95 × 1.5** for the first 14 days. This dampens false positives while baseline data accumulates. After T+14 days, alerting tightens to p95 × 1.0 (per Phase 2).

### Phase 2 — Measured (scheduled 2026-05-09)

After 14 days of production traffic spanning weekday + weekend + one release cycle, the team will:

1. Pull p95 measurements from Firebase Performance dashboard (mobile) and Sentry transactions (web)
2. Update this document with the measured values
3. Promote alert thresholds to p95 × 1.0
4. Open an ADR-027 amendment if any measured p95 exceeds the Phase 1 SLO by >50% (signals an unacknowledged performance regression in Sprint 9–10)

## Operational

- **Sampling:** production 100%; debug disabled. Remote Config kill switch `perf_trace_sample_rate` (default 1.0) — flippable without redeploy.
- **Owner:** belengaz (`@mahmutkaya`) for SLO operations + alerting; pizmam (`@emredursun`) for trace boundary definitions.
- **Review cadence:** 90 days (next: 2026-07-24).

## Cross-references

- **ADR-027** — Performance instrumentation strategy
- **`docs/observability/trace-registry.md`** — Per-trace boundary conventions + attributes
- **`docs/PLAN-P56-firebase-performance-traces.md`** — Implementation plan
- **Audit `H5`** — `docs/audits/2026-04-25-tier1-preflight.md`
