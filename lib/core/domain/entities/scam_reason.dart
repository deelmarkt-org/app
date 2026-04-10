/// Reason the AI scam detector flagged a message.
///
/// This is the **single source of truth** for scam reason types across the
/// domain and widget layers (CLAUDE.md §3.3 — no duplication). The P-34
/// `ScamAlert` widget in `lib/widgets/trust/` imports this enum; the P-37
/// chat integration maps `MessageEntity.scamReasons` to `ScamAlert.reasons`
/// via this shared type.
///
/// The values align with the E06 backend scam-detection classifier output.
/// If the backend adds new reason types, extend this enum and add
/// corresponding l10n keys under `scam_alert.reason.*`.
///
/// Reference:
/// - docs/epics/E06-trust-moderation.md §Scam Detection
/// - docs/screens/06-chat/03-scam-alert.md
enum ScamReason {
  /// Message contains a link to an external payment site or shortened URL.
  externalPaymentLink,

  /// Message asks to move the conversation or transaction off-platform.
  offSiteContact,

  /// Message solicits a phone number, WhatsApp, Telegram, etc.
  phoneNumberRequest,

  /// Price or offer is suspiciously below market value.
  suspiciousPricing,

  /// Message uses urgency pressure ("now", "today only", "limited time").
  urgencyPressure,

  /// Message asks for credentials, passwords, BSN, or identity documents.
  credentialHarvesting,

  /// Message requests advance payment or deposit before delivery.
  advancePaymentRequest,

  /// Message promotes a fake or external escrow service.
  fakeEscrow,

  /// Message contains a shipping-related scam pattern.
  shippingScam,

  /// Message references prohibited items (weapons, drugs, stolen goods).
  prohibitedItem,

  /// Detector flagged the message but did not classify the reason.
  other;

  /// Localisation key under `scam_alert.reason.*` in l10n JSON files.
  ///
  /// Uses `snake_case` dot-separated keys per CLAUDE.md §2.2.
  String get localizationKey => switch (this) {
    ScamReason.externalPaymentLink => 'scam_alert.reason.external_payment_link',
    ScamReason.offSiteContact => 'scam_alert.reason.off_site_contact',
    ScamReason.phoneNumberRequest => 'scam_alert.reason.phone_number_request',
    ScamReason.suspiciousPricing => 'scam_alert.reason.suspicious_pricing',
    ScamReason.urgencyPressure => 'scam_alert.reason.urgency_pressure',
    ScamReason.credentialHarvesting =>
      'scam_alert.reason.credential_harvesting',
    ScamReason.advancePaymentRequest =>
      'scam_alert.reason.advance_payment_request',
    ScamReason.fakeEscrow => 'scam_alert.reason.fake_escrow',
    ScamReason.shippingScam => 'scam_alert.reason.shipping_scam',
    ScamReason.prohibitedItem => 'scam_alert.reason.prohibited_item',
    ScamReason.other => 'scam_alert.reason.other',
  };

  /// Maps a DB string value to [ScamReason]. Falls back to [other].
  static ScamReason fromDb(String value) => switch (value) {
    'external_payment_link' => ScamReason.externalPaymentLink,
    'off_site_contact' => ScamReason.offSiteContact,
    'phone_number_request' => ScamReason.phoneNumberRequest,
    'suspicious_pricing' => ScamReason.suspiciousPricing,
    'urgency_pressure' => ScamReason.urgencyPressure,
    'credential_harvesting' => ScamReason.credentialHarvesting,
    'advance_payment_request' => ScamReason.advancePaymentRequest,
    'fake_escrow' => ScamReason.fakeEscrow,
    'shipping_scam' => ScamReason.shippingScam,
    'prohibited_item' => ScamReason.prohibitedItem,
    _ => ScamReason.other,
  };
}

/// Confidence level assigned by the E06 scam detector to a message.
///
/// - [none]: not flagged — do **not** render a `ScamAlert` widget.
/// - [low]: soft signal — UI shows a **dismissible** amber banner.
/// - [high]: strong signal — UI shows a **non-dismissible** red banner
///   with a mandatory Report action.
///
/// When mapping to the P-34 `ScamAlert` widget:
/// ```
/// none → do not render the widget
/// low  → ScamAlertConfidence.low   (dismissible amber)
/// high → ScamAlertConfidence.high  (non-dismissible red, onReport required)
/// ```
///
/// Reference: docs/epics/E06-trust-moderation.md §Scam Detection
enum ScamConfidence {
  none,
  low,
  high;

  /// Maps a DB string value to [ScamConfidence]. Falls back to [none].
  static ScamConfidence fromDb(String? value) => switch (value) {
    'low' => ScamConfidence.low,
    'high' => ScamConfidence.high,
    _ => ScamConfidence.none,
  };
}
