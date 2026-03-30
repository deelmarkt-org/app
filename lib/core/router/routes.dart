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
  static const profile = '/profile';

  // ── Auth flow ──
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';

  // ── Deep link targets ──
  static const listingDetail = '/listings/:id';
  static const userProfile = '/users/:id';
  static const transactionDetail = '/transactions/:id';
  static const shippingDetail = '/shipping/:id';
  static const shippingQr = '/shipping/:id/qr';
  static const shippingTracking = '/shipping/:id/tracking';
  static const parcelShopSelector = '/shipping/:id/parcel-shops';
}
