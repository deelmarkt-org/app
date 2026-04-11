/// Centralised route path constants.
///
/// All route paths are defined here to avoid magic strings.
/// Deep link paths must match .well-known/apple-app-site-association
/// and .well-known/assetlinks.json.
abstract final class AppRoutes {
  // ── Bottom navigation tabs ──
  static const home = '/';
  static const search = '/search';
  static const sell = '/sell';
  static const messages = '/messages';
  static const chatThread = '/messages/:conversationId';

  /// Builds the concrete path for a chat thread.
  ///
  /// Percent-encodes [conversationId] so path-significant characters
  /// (`/`, `?`, `#`, etc.) cannot truncate or misroute the URL if a
  /// non-UUID id ever reaches this helper (security finding F-06).
  static String chatThreadFor(String conversationId) =>
      '/messages/${Uri.encodeComponent(conversationId)}';

  /// Builds the concrete path for a shipping detail screen.
  ///
  /// Percent-encodes [shippingLabelId] for the same reason as [chatThreadFor].
  static String shippingDetailFor(String shippingLabelId) =>
      '/shipping/${Uri.encodeComponent(shippingLabelId)}';

  /// Builds the concrete path for a transaction detail screen.
  ///
  /// Used by the seller "Ship order" action tile to navigate to the transaction,
  /// from which the user can open the shipping flow.
  static String transactionDetailFor(String transactionId) =>
      '/transactions/${Uri.encodeComponent(transactionId)}';

  static const profile = '/profile';

  /// Bottom nav tab indices — must match StatefulShellBranch order in app_router.
  static const sellTabIndex = 2;

  static const settings = '/profile/settings';

  // ── Auth flow ──
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';

  // ── Category & Favourites ──
  static const categories = '/categories';
  static const categoryDetail = '/categories/:id';
  static const favourites = '/favourites';

  // ── Deep link targets ──
  static const listingDetail = '/listings/:id';
  static const userProfile = '/users/:id';
  static const transactionDetail = '/transactions/:id';
  static const transactionReview = '/transactions/:id/review';
  static const shippingDetail = '/shipping/:id';
  static const shippingQr = '/shipping/:id/qr';
  static const shippingTracking = '/shipping/:id/tracking';
  static const parcelShopSelector = '/shipping/:id/parcel-shops';

  // ── Admin panel ──
  static const admin = '/admin';
  static const adminFlaggedListings = '/admin/flagged-listings';
  static const adminReportedUsers = '/admin/reported-users';
  static const adminDisputes = '/admin/disputes';
  static const adminDisputeDetail = '/admin/disputes/:id';
  static const adminDsaNotices = '/admin/dsa-notices';
  static const adminAppeals = '/admin/appeals';
}
