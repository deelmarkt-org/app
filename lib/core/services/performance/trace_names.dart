/// Canonical trace name registry.
///
/// All custom-trace names live here as `const` strings so they are
/// referenced symbolically (CLAUDE.md §3.3 — no inline string literals).
///
/// Adding a new trace? Update `docs/observability/trace-registry.md` first
/// — boundary conventions belong in the doc, names belong here.
abstract final class TraceNames {
  /// Cold-start measured from `WidgetsFlutterBinding.ensureInitialized()`
  /// to first frame of the root navigator.
  static const String appStart = 'app_start';

  /// Listing detail load measured from `GetListingDetailUseCase.execute()`
  /// to first paint with hero image + price + seller row visible.
  static const String listingLoad = 'listing_load';

  /// Search query measured from first post-debounce committed query to
  /// first row visible in the results view (not per-keystroke).
  static const String searchQuery = 'search_query';

  /// Payment intent creation measured from `CreatePaymentUseCase.execute()`
  /// to Mollie WebView load complete (or error).
  static const String paymentCreate = 'payment_create';

  /// Image load measured from `cached_network_image` fetch start to
  /// decode-success or decode-error.
  static const String imageLoad = 'image_load';
}
