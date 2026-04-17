# ADR-022: Image Delivery Pipeline — `cached_network_image` + Cloudinary Transforms

### Status

**Accepted** — 2026-04-17 · Author: pizmam · Reviewers pending: belengaz (Cloudinary ops), reso (Storage egress)

### Context

`lib/widgets/cards/deel_card_image.dart:44` and `lib/features/home/presentation/widgets/listing_card.dart:130` currently use `Image.network`. This:

1. Has **no disk cache** — every scroll re-downloads, violating P-45 perf budget.
2. Decodes at full resolution → OOM risk on mid-tier Android (Galaxy A32 class, ~300MB app budget).
3. Re-triggers Cloudinary egress per view → free-tier (25GB/mo) projected to overflow at ~500 listings × 300KB × 10 views/day.
4. Has no Sentry/Crashlytics hook → silent failures invisible in production.
5. On Flutter Web (shipping per P-45/P-48), `Image.network` degrades to the browser's opaque cache with no control over eviction or sizing.

GitHub issue [#60](https://github.com/deelmarkt-org/app/issues/60) tracks the replacement. This ADR formalizes the decision.

### Decision

Adopt **`cached_network_image: ^3.4.1`** as the canonical image loader for all network-sourced imagery across mobile and Web. Couple with:

1. **Custom `DeelCacheManager`** (`lib/core/services/image_cache_manager.dart`):
   - `stalePeriod: Duration(days: 7)`
   - `maxNrOfCacheObjects: 200`
   - `PaintingBinding.instance.imageCache.maximumSize = 100`
   - `PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024` (50 MB)
2. **`DeelImageUrl` helper** (`lib/core/utils/deel_image_url.dart`) that rewrites Cloudinary URLs with `f_auto,q_auto,w_{target}` transforms derived from `MediaQuery.devicePixelRatio × renderWidth`.
3. **Sentry error listener** on every `CachedNetworkImage` — capture `image_load_failed` with `{url_hash, http_status}` (URL is sha256-hashed, no PII).
4. **Flutter Web guard**: pre-flight CORS check committed as `docs/verifications/cdn-cors.md`; CI job runs `curl` headers assertion weekly.

### Consequences

#### Positive
- 60%+ bandwidth reduction via `q_auto` (confirmed from Cloudinary benchmark docs).
- Disk cache turns scroll-back into instant load; p95 scroll frame time targeted < 16ms.
- Bounded decoded memory (50 MB ceiling) → no OOM on mid-tier devices.
- Observability: image failures become first-class incidents in Sentry.
- Web + mobile share the same API; Web disk cache falls through to browser's built-in (acceptable).

#### Negative
- New transitive deps: `flutter_cache_manager`, `path_provider`, `sqflite` (mobile only). `path_provider` init must precede first image load.
- Flutter Web uses `window.fetch` — requires Cloudinary + Supabase Storage CORS headers to include our origins (verified pre-merge, see `docs/verifications/cdn-cors.md`).
- Golden test drift expected from fade-in curve difference (`CachedNetworkImage.fadeInDuration/fadeInCurve` vs stdlib rendering). Mitigated by `test/helpers/tolerant_golden_comparator.dart` (already in tree).

### Alternatives Considered

1. **`extended_image`** — rejected: 2× bundle size; feature surface (editor, crop) unused.
2. **`octo_image`** — rejected: good composition primitive but requires we own the caching layer; reinvents what `cached_network_image` provides.
3. **Vendor SDK `cloudinary_flutter`** — rejected for runtime loading: solves server-side transforms (already used on upload), not client cache. Complementary, not replacement.
4. **Stay with `Image.network` + manual `precacheImage`** — rejected: no disk cache, no Web parity, no observability.

### Rollback

Single-commit revert; `CachedNetworkImage` has identical API surface (url, width, height, fit, loadingBuilder, errorBuilder → placeholder, errorWidget). Cache dir `.deel_image_cache` can be deleted on rollback via `DefaultCacheManager().emptyCache()`.
