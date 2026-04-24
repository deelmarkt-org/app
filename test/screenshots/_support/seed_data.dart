/// Deterministic seed-data configuration for screenshot generation.
///
/// All persona data uses fictitious details that are:
///  - @example.invalid emails (not real inboxes)
///  - Fictional Dutch addresses
///  - Generic public-domain product images (Cloudinary demo)
///  - No BSN, IBAN, or real phone numbers
///
/// This is the SINGLE source of truth for screenshot data — never use real
/// user data in screenshots (GDPR / App Store review requirement).
///
/// See PLAN-p43-aso.md §3.1 Security (R-4 PII mitigation).
library;

/// The current user shown as "me" in own-profile / chat screens.
const kScreenshotCurrentUserId = 'screenshot-user-001';

/// Listing ID to use as the "featured" listing for detail-screen screenshots.
const kScreenshotFeaturedListingId = 'listing-001';

/// Conversation ID to use for the chat-thread screenshot.
const kScreenshotConversationId = 'conv-001';

/// Transaction ID to use for the transaction-detail screenshot.
const kScreenshotTransactionId = 'txn-001';

/// Shipping order reference for the QR screen.
const kScreenshotShipmentId = 'shipment-001';

/// Category ID for category-detail screenshot (L1 electronics — populated
/// with subcategories + featured listings in the mock category data).
const kScreenshotCategoryId = 'cat-electronics';

/// Locale variants to capture for each device × theme combination.
const kScreenshotLocales = ['nl_NL', 'en_US'];

/// Theme variants to capture.
enum ScreenshotTheme { light, dark }

/// The frozen "now" timestamp used by screens that display relative time.
///
/// All mock timestamps are set relative to this anchor so "2 hours ago",
/// "yesterday" etc. are stable across runs.
final kScreenshotNow = DateTime(2026, 4, 15, 14);
