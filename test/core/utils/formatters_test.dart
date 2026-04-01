import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:deelmarkt/core/utils/formatters.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('nl');
    await initializeDateFormatting('en');
  });

  group('Formatters.euroFromCents', () {
    test('formats whole euros', () {
      expect(Formatters.euroFromCents(4500), '\u20AC\u00A045,00');
    });

    test('formats cents', () {
      expect(Formatters.euroFromCents(113), '\u20AC\u00A01,13');
    });

    test('formats zero', () {
      expect(Formatters.euroFromCents(0), '\u20AC\u00A00,00');
    });
  });

  group('Formatters.distanceKm', () {
    test('formats with Dutch comma decimal', () {
      expect(Formatters.distanceKm(3.2), '3,2 km');
    });

    test('formats whole number', () {
      expect(Formatters.distanceKm(5.0), '5,0 km');
    });

    test('formats long decimal', () {
      expect(Formatters.distanceKm(12.567), '12,6 km');
    });
  });

  group('Formatters.shortDateTime', () {
    test('formats with Dutch locale', () {
      final dt = DateTime(2026, 3, 25, 18);
      final result = Formatters.shortDateTime(dt);
      expect(result, contains('25'));
      expect(result, contains('2026'));
      expect(result, contains('18:00'));
    });

    test('formats with English locale', () {
      final dt = DateTime(2026, 3, 25, 18);
      final result = Formatters.shortDateTime(dt, locale: 'en');
      expect(result, contains('25'));
      expect(result, contains('Mar'));
      expect(result, contains('2026'));
      expect(result, contains('18:00'));
    });

    test('defaults to Dutch locale', () {
      final dt = DateTime(2026);
      final result = Formatters.shortDateTime(dt);
      expect(result, contains('2026'));
      expect(result, contains('00:00'));
    });

    test('handles midnight correctly', () {
      final dt = DateTime(2026, 12, 31);
      final result = Formatters.shortDateTime(dt, locale: 'en');
      expect(result, contains('00:00'));
      expect(result, contains('31'));
    });

    test('handles single-digit day', () {
      final dt = DateTime(2026, 1, 5, 9, 30);
      final result = Formatters.shortDateTime(dt, locale: 'en');
      expect(result, contains('5'));
      expect(result, contains('09:30'));
    });
  });
}
