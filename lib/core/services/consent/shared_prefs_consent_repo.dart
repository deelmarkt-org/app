import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/services/consent/consent_record.dart';
import 'package:deelmarkt/core/services/consent/consent_repository.dart';

/// SharedPreferences-backed consent persistence (MVP).
///
/// Stores consent as a JSON string. Corrupted data triggers re-consent
/// (returns null) rather than throwing — safe default for GDPR compliance.
///
/// Phase 2 (reso): replace with Didomi CMP adapter.
class SharedPrefsConsentRepository implements ConsentRepository {
  SharedPrefsConsentRepository(this._prefs);

  static const _key = 'gdpr_consent_record';
  final SharedPreferences _prefs;

  @override
  Future<ConsentRecord?> getConsent() async {
    try {
      final raw = _prefs.getString(_key);
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return ConsentRecord.fromJson(json);
    } on Exception catch (_) {
      // Corrupted data — delete and force re-consent.
      // Never log raw JSON (may contain PII metadata).
      await _prefs.remove(_key);
      return null;
    }
  }

  @override
  Future<void> saveConsent(ConsentRecord record) async {
    await _prefs.setString(_key, jsonEncode(record.toJson()));
  }

  @override
  Future<void> clearConsent() async {
    await _prefs.remove(_key);
  }
}
