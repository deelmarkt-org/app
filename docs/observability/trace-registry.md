# DeelMarkt — Trace Registry

> Authoritative per-trace boundary conventions, attributes, and ownership.
> Source of truth for trace name constants: `lib/core/services/performance/trace_names.dart`.

## How to add a new trace

1. **Update this document first** — define boundary convention, attributes, owner, and provisional p95 SLO.
2. Add the constant to `lib/core/services/performance/trace_names.dart`.
3. Add SLO row to `docs/observability/perf-slos.md`.
4. Wire the trace in code (start/stop pair).
5. Add a contract test (lifecycle: success / throw / cancel paths).
6. Bump ADR-027 if the trace requires architectural changes.

---

## Active traces (v1)

### `app_start`

| Field | Value |
|-------|-------|
| **Constant** | `TraceNames.appStart` |
| **Owner** | pizmam |
| **Start boundary** | First line after `await initSentry()` in `lib/main.dart`. `initSentry()` must precede the start so `SentryPerformanceTracer` attaches to a real Sentry hub instead of the pre-init `NoOpHub` (PR #247). The Firebase tracer is unaffected by this ordering, but the boundary is held consistent across backends so SLO comparisons stay apples-to-apples. The ~100–200 ms `initSentry()` cost is therefore **excluded** from `app_start` — record this when calibrating the p95 ≤ 2.5 s SLO. |
| **Stop boundary** | `WidgetsBinding.addPostFrameCallback` after first frame of root navigator |
| **Sub-metrics** | `splash_to_first_frame_ms`, `dependencies_init_ms` |
| **Attributes** | `platform`, `network_type`, `locale` |
| **p95 SLO (Phase 1)** | 2.5 s |
| **Status** | 🟡 Defined — wiring follow-up (P-56 Phase B) |

### `listing_load`

| Field | Value |
|-------|-------|
| **Constant** | `TraceNames.listingLoad` |
| **Owner** | pizmam (UI boundary) + reso (data boundary) |
| **Start boundary** | `GetListingDetailUseCase.execute()` invocation |
| **Stop boundary** | `addPostFrameCallback` after `AsyncData` first paint with hero image visible |
| **Sub-metrics** | `gallery_loaded_ms`, `seller_loaded_ms` |
| **Attributes** | `cache_hit`, `listing_category`, `listing_price_bucket`, `network_type` |
| **p95 SLO (Phase 1)** | 1.5 s |
| **Status** | 🟡 Defined — wiring follow-up (P-56 Phase B) |
| **Note** | "Loaded" = user can read price + decide to scroll. Gallery completion is a sub-metric, not the stop boundary. |

### `search_query`

| Field | Value |
|-------|-------|
| **Constant** | `TraceNames.searchQuery` |
| **Owner** | belengaz (search infra) + pizmam (UI boundary) |
| **Start boundary** | First **post-debounce** committed query (NOT per keystroke) |
| **Stop boundary** | First row visible in `SearchResultsView` |
| **Sub-metrics** | `result_count` (bucketed) |
| **Attributes** | `result_count`, `cache_hit`, `network_type`, `locale` |
| **p95 SLO (Phase 1)** | 800 ms |
| **Status** | 🟡 Defined — wiring follow-up (P-56 Phase B) |

### `payment_create`

| Field | Value |
|-------|-------|
| **Constant** | `TraceNames.paymentCreate` |
| **Owner** | belengaz |
| **Start boundary** | `CreatePaymentUseCase.execute()` invocation |
| **Stop boundary** | Mollie WebView `onLoadStop` (success) OR error caught (`catch`) |
| **Sub-metrics** | `mollie_response_ms` |
| **Attributes** | `payment_method`, `network_type`, `listing_price_bucket` |
| **p95 SLO (Phase 1)** | 3.0 s |
| **Status** | 🟡 Defined — wiring follow-up (P-56 Phase B) |
| **Note** | CLAUDE.md §6.1 requires 100% test coverage on payment paths. Tracer integration must not regress this. |

### `image_load`

| Field | Value |
|-------|-------|
| **Constant** | `TraceNames.imageLoad` |
| **Owner** | pizmam |
| **Start boundary** | `cached_network_image` `imageBuilder` / `errorWidget` callback wrap point in `lib/widgets/cards/deel_card_image.dart` and `lib/widgets/media/image_gallery_page.dart` |
| **Stop boundary** | Decode-success or decode-error |
| **Sub-metrics** | (none — single-shot) |
| **Attributes** | `cache_hit`, `image_size_bucket`, `network_type` |
| **p95 SLO (Phase 1)** | 1.2 s |
| **Status** | 🟡 Defined — wiring follow-up (P-56 Phase B) |
| **Cross-ref** | ADR-022 image-delivery pipeline |

---

## Attribute reference

See `lib/core/services/performance/trace_attributes.dart` for the canonical allowlist + bucketing helpers.

**Allowlist (safe):** `locale`, `platform`, `network_type`, `cache_hit`, `result_count`, `image_size_bucket`, `payment_method`, `listing_category`, `listing_price_bucket`.

**Forbid list (PII):** `user_id`, `email`, `listing_id`, `search_term`, `coordinates` / `lat` / `lon`, `device_id`, `ip`.

For ad-hoc debug context that requires PII (e.g. a specific listing ID), use Sentry breadcrumbs (PII-aware, scrubbed, 30-day retention) — never trace attributes.

---

## Status legend

- ✅ Wired and reporting in production
- 🟡 Defined in code (constant + boundary doc) but not yet wired at the call site
- 🔵 Wiring in progress (open PR)
- ❌ Removed (do not delete the row — keep history)

## Maintenance

- **Owner:** pizmam + belengaz (joint)
- **Review cadence:** 90 days (next: 2026-07-24)
- **Adding a new trace:** see "How to add a new trace" at the top
