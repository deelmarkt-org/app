/// Classifier reasons surfaced by the E06 scam-detection backend.
///
/// Mapping backend flag → this enum lives outside the widget so that the
/// widget API only accepts a finite, safe set of reason values. A raw
/// user-controlled string would create a rendering / injection surface.
///
/// Reference:
/// - `docs/design-system/patterns.md` §Scam Alert (Inline)
/// - `docs/screens/06-chat/03-scam-alert.md`
enum ScamAlertReason {
  externalPaymentLink,
  phoneNumberRequest,
  offSiteContact,
  suspiciousPricing,
  other;

  /// Localisation key under the `scam_alert.reasons.*` namespace.
  String get l10nKey => switch (this) {
    ScamAlertReason.externalPaymentLink =>
      'scam_alert.reasons.externalPaymentLink',
    ScamAlertReason.phoneNumberRequest =>
      'scam_alert.reasons.phoneNumberRequest',
    ScamAlertReason.offSiteContact => 'scam_alert.reasons.offSiteContact',
    ScamAlertReason.suspiciousPricing => 'scam_alert.reasons.suspiciousPricing',
    ScamAlertReason.other => 'scam_alert.reasons.other',
  };
}

/// Confidence tier of the scam classifier.
///
/// `high` → red, non-dismissible, Report button required.
/// `low`  → amber, dismissible, no Report button required.
enum ScamAlertConfidence { high, low }
