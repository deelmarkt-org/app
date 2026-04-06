/// Reason the AI scam detector flagged a message.
///
/// Used by [MessageEntity.scamReasons] and surfaced in the P-37 scam alert
/// expanded panel. Each value maps to a localization key so the UI can render
/// the reason in NL/EN.
///
/// Reference:
/// - docs/epics/E06-trust-moderation.md §Scam Detection
/// - docs/screens/06-chat/03-scam-alert.md
enum ScamReason {
  /// Message contains a link to an external payment site or shortened URL.
  externalPaymentLink,

  /// Message asks to move the conversation or transaction off-platform.
  offPlatformRequest,

  /// Message solicits a phone number, WhatsApp, Telegram, etc.
  phoneNumberSolicitation,

  /// Price or offer is suspiciously below market value.
  tooGoodToBeTrue,

  /// Message uses urgency pressure ("now", "today only", "limited time").
  urgencyPressure,

  /// Detector flagged the message but did not classify the reason.
  unknown,
}

/// Extension providing the localization key for each [ScamReason].
extension ScamReasonLocalization on ScamReason {
  /// Localization key under `scamAlert.reason.*` in l10n JSON files.
  String get localizationKey {
    switch (this) {
      case ScamReason.externalPaymentLink:
        return 'scamAlert.reason.externalPaymentLink';
      case ScamReason.offPlatformRequest:
        return 'scamAlert.reason.offPlatformRequest';
      case ScamReason.phoneNumberSolicitation:
        return 'scamAlert.reason.phoneNumberSolicitation';
      case ScamReason.tooGoodToBeTrue:
        return 'scamAlert.reason.tooGoodToBeTrue';
      case ScamReason.urgencyPressure:
        return 'scamAlert.reason.urgencyPressure';
      case ScamReason.unknown:
        return 'scamAlert.reason.unknown';
    }
  }
}
