import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:deelmarkt/core/utils/time_ago.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('nl');
    await initializeDateFormatting('en');
  });

  group('formatTimeAgo NL', () {
    test('seconds ago returns Zojuist', () {
      final dt = DateTime.now().subtract(const Duration(seconds: 30));
      expect(formatTimeAgo(dt), 'Zojuist');
    });

    test('1 minute ago', () {
      final dt = DateTime.now().subtract(const Duration(minutes: 1));
      expect(formatTimeAgo(dt), '1 minuut geleden');
    });

    test('multiple minutes ago', () {
      final dt = DateTime.now().subtract(const Duration(minutes: 15));
      expect(formatTimeAgo(dt), '15 minuten geleden');
    });

    test('1 hour ago', () {
      final dt = DateTime.now().subtract(const Duration(hours: 1));
      expect(formatTimeAgo(dt), '1 uur geleden');
    });

    test('multiple hours ago', () {
      final dt = DateTime.now().subtract(const Duration(hours: 5));
      expect(formatTimeAgo(dt), '5 uur geleden');
    });

    test('1 day ago returns Gisteren', () {
      final dt = DateTime.now().subtract(const Duration(days: 1));
      expect(formatTimeAgo(dt), 'Gisteren');
    });

    test('multiple days ago', () {
      final dt = DateTime.now().subtract(const Duration(days: 3));
      expect(formatTimeAgo(dt), '3 dagen geleden');
    });

    test('1 week ago', () {
      final dt = DateTime.now().subtract(const Duration(days: 10));
      expect(formatTimeAgo(dt), '1 week geleden');
    });

    test('multiple weeks ago', () {
      final dt = DateTime.now().subtract(const Duration(days: 21));
      expect(formatTimeAgo(dt), '3 weken geleden');
    });

    test('1 month ago', () {
      final dt = DateTime.now().subtract(const Duration(days: 35));
      expect(formatTimeAgo(dt), '1 maand geleden');
    });

    test('multiple months ago', () {
      final dt = DateTime.now().subtract(const Duration(days: 120));
      expect(formatTimeAgo(dt), '4 maanden geleden');
    });

    test('1 year ago', () {
      final dt = DateTime.now().subtract(const Duration(days: 400));
      expect(formatTimeAgo(dt), '1 jaar geleden');
    });

    test('2+ years falls back to absolute date', () {
      final dt = DateTime(2023, 6, 15);
      final result = formatTimeAgo(dt);
      expect(result, contains('2023'));
    });

    test('future date returns absolute date', () {
      final dt = DateTime.now().add(const Duration(days: 10));
      final result = formatTimeAgo(dt);
      expect(result, isNotEmpty);
    });
  });

  group('formatTimeAgo EN', () {
    test('seconds ago returns Just now', () {
      final dt = DateTime.now().subtract(const Duration(seconds: 10));
      expect(formatTimeAgo(dt, locale: 'en'), 'Just now');
    });

    test('1 minute ago', () {
      final dt = DateTime.now().subtract(const Duration(minutes: 1));
      expect(formatTimeAgo(dt, locale: 'en'), '1 minute ago');
    });

    test('multiple hours ago', () {
      final dt = DateTime.now().subtract(const Duration(hours: 3));
      expect(formatTimeAgo(dt, locale: 'en'), '3 hours ago');
    });

    test('yesterday', () {
      final dt = DateTime.now().subtract(const Duration(days: 1));
      expect(formatTimeAgo(dt, locale: 'en'), 'Yesterday');
    });
  });

  group('formatMemberSince', () {
    test('NL locale', () {
      final dt = DateTime(2025, 6);
      final result = formatMemberSince(dt);
      expect(result, startsWith('Lid sinds'));
      expect(result, contains('2025'));
    });

    test('EN locale', () {
      final dt = DateTime(2025, 6);
      final result = formatMemberSince(dt, locale: 'en');
      expect(result, startsWith('Member since'));
      expect(result, contains('2025'));
    });
  });
}
