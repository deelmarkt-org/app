import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/services/consent/consent_record.dart';

void main() {
  ConsentRecord createRecord({
    ConsentLevel level = ConsentLevel.allCookies,
    String version = '1.0.0',
    String locale = 'nl',
  }) {
    return ConsentRecord(
      level: level,
      version: version,
      timestamp: DateTime.utc(2026, 3, 24, 12, 0),
      locale: locale,
      source: ConsentSource.banner,
      purposes: {
        ConsentPurpose.essential: true,
        ConsentPurpose.analytics: level == ConsentLevel.allCookies,
        ConsentPurpose.marketing: level == ConsentLevel.allCookies,
      },
    );
  }

  group('ConsentRecord', () {
    test('toJson/fromJson roundtrip preserves all fields', () {
      final original = createRecord();
      final restored = ConsentRecord.fromJson(original.toJson());

      expect(restored.level, original.level);
      expect(restored.version, original.version);
      expect(restored.timestamp, original.timestamp);
      expect(restored.locale, original.locale);
      expect(restored.source, original.source);
      expect(restored.purposes, original.purposes);
    });

    test('isOutdated returns true when version differs', () {
      final record = createRecord(version: '0.9.0');
      expect(record.isOutdated('1.0.0'), isTrue);
    });

    test('isOutdated returns false when version matches', () {
      final record = createRecord(version: '1.0.0');
      expect(record.isOutdated('1.0.0'), isFalse);
    });

    test('timestamp is stored as UTC ISO 8601', () {
      final record = createRecord();
      final json = record.toJson();
      expect(json['timestamp'], endsWith('Z'));
      expect(json['timestamp'], '2026-03-24T12:00:00.000Z');
    });

    test('necessaryOnly level sets analytics/marketing to false', () {
      final record = createRecord(level: ConsentLevel.necessaryOnly);
      expect(record.purposes[ConsentPurpose.essential], isTrue);
      expect(record.purposes[ConsentPurpose.analytics], isFalse);
      expect(record.purposes[ConsentPurpose.marketing], isFalse);
    });

    test('fromJson throws on invalid level', () {
      expect(
        () => ConsentRecord.fromJson({'level': 'invalid', 'version': '1'}),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
