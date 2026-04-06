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

  /// Detector flagged the message but did not classify the reason.
  other;

  /// Localisation key under `scam_alert.reason.*` in l10n JSON files.
  ///
  /// Uses `snake_case` dot-separated keys per CLAUDE.md §2.2.
  String get localizationKey => switch (this) {
    ScamReason.externalPaymentLink => 'scam_alert.reason.externalPaymentLink',
    ScamReason.offSiteContact => 'scam_alert.reason.offSiteContact',
    ScamReason.phoneNumberRequest => 'scam_alert.reason.phoneNumberRequest',
    ScamReason.suspiciousPricing => 'scam_alert.reason.suspiciousPricing',
    ScamReason.urgencyPressure => 'scam_alert.reason.urgencyPressure',
    ScamReason.other => 'scam_alert.reason.other',
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
enum ScamConfidence { none, low, high }
