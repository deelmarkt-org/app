/// Reason the AI scam detector flagged a message.
///
/// Used by [MessageEntity.scamReasons] and surfaced in the P-37 scam alert
/// expanded panel. Each value maps to a localization key so the UI can render
/// the reason in NL/EN.
///
/// **Canonical set** — aligns with PR #72 (merged to dev):
/// `externalPaymentLink`, `offSiteContact`, `phoneNumberRequest`,
/// `suspiciousPricing`, `urgencyPressure`, `other`.
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

  /// Detector flagged the message but did not classify the reason.
  other,
}

/// Extension providing the localization key for each [ScamReason].
extension ScamReasonLocalization on ScamReason {
  /// Localization key under `scam_alert.reason.*` in l10n JSON files.
  String get localizationKey {
    switch (this) {
      case ScamReason.externalPaymentLink:
        return 'scam_alert.reason.externalPaymentLink';
      case ScamReason.offSiteContact:
        return 'scam_alert.reason.offSiteContact';
      case ScamReason.phoneNumberRequest:
        return 'scam_alert.reason.phoneNumberRequest';
      case ScamReason.suspiciousPricing:
        return 'scam_alert.reason.suspiciousPricing';
      case ScamReason.urgencyPressure:
        return 'scam_alert.reason.urgencyPressure';
      case ScamReason.other:
        return 'scam_alert.reason.other';
    }
  }
}
