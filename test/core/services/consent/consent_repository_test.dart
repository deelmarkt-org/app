import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/services/consent/consent_record.dart';
import 'package:deelmarkt/core/services/consent/shared_prefs_consent_repo.dart';

void main() {
  late SharedPreferences prefs;
  late SharedPrefsConsentRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repo = SharedPrefsConsentRepository(prefs);
  });

  ConsentRecord createRecord({
    ConsentLevel level = ConsentLevel.allCookies,
    String version = '1.0.0',
  }) {
    return ConsentRecord(
      level: level,
      version: version,
      timestamp: DateTime.utc(2026, 3, 24, 12, 0),
      locale: 'nl',
      source: ConsentSource.banner,
      purposes: {
        ConsentPurpose.essential: true,
        ConsentPurpose.analytics: level == ConsentLevel.allCookies,
        ConsentPurpose.marketing: level == ConsentLevel.allCookies,
      },
    );
  }

  group('SharedPrefsConsentRepository', () {
    test('getConsent returns null when no consent stored', () async {
      expect(await repo.getConsent(), isNull);
    });

    test('saveConsent then getConsent returns same record', () async {
      final record = createRecord();
      await repo.saveConsent(record);

      final restored = await repo.getConsent();
      expect(restored, isNotNull);
      expect(restored!.level, record.level);
      expect(restored.version, record.version);
      expect(restored.timestamp, record.timestamp);
      expect(restored.locale, record.locale);
      expect(restored.source, record.source);
      expect(restored.purposes, record.purposes);
    });

    test('clearConsent removes stored consent', () async {
      await repo.saveConsent(createRecord());
      await repo.clearConsent();
      expect(await repo.getConsent(), isNull);
    });

    test('corrupted JSON returns null and deletes key', () async {
      await prefs.setString('gdpr_consent_record', '{invalid json!!!}');
      final result = await repo.getConsent();
      expect(result, isNull);
      // Key should be cleaned up
      expect(prefs.getString('gdpr_consent_record'), isNull);
    });

    test('version field preserved across save/load', () async {
      final record = createRecord(version: '2.1.0');
      await repo.saveConsent(record);
      final restored = await repo.getConsent();
      expect(restored!.version, '2.1.0');
    });

    test(
      'consent persists across new repository instance (app restart)',
      () async {
        // Save consent with first repo instance.
        await repo.saveConsent(createRecord(version: '1.0.0'));

        // Create a new repo instance (simulates app restart).
        final newRepo = SharedPrefsConsentRepository(prefs);
        final restored = await newRepo.getConsent();
        expect(restored, isNotNull);
        expect(restored!.version, '1.0.0');
        expect(restored.level, ConsentLevel.allCookies);
      },
    );

    test('multiple sequential writes produce consistent state', () async {
      await repo.saveConsent(createRecord(level: ConsentLevel.allCookies));
      await repo.saveConsent(createRecord(level: ConsentLevel.necessaryOnly));
      final restored = await repo.getConsent();
      expect(restored!.level, ConsentLevel.necessaryOnly);
    });
  });
}
