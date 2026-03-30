import 'package:deelmarkt/core/services/consent/consent_record.dart';

/// Consent persistence interface.
///
/// MVP: [SharedPrefsConsentRepository]. Phase 2: Didomi CMP (IAB TCF 2.2).
/// Phase 2 (reso): server-side sync for GDPR audit trail.
abstract class ConsentRepository {
  Future<ConsentRecord?> getConsent();
  Future<void> saveConsent(ConsentRecord record);

  /// GDPR Article 7(3) — withdrawal must be as easy as giving consent.
  Future<void> clearConsent();
}
