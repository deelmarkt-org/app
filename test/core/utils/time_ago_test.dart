import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:deelmarkt/core/utils/time_ago.dart';

// In test environments without easy_localization setup, .tr() returns the
// l10n key path (e.g. 'time_ago.just_now'). Tests verify the correct key
// is selected rather than the translated string value.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('nl');
    await initializeDateFormatting('en');
  });

  group('formatTimeAgo key selection', () {
    test('seconds ago returns justNow key', () {
      final dt = DateTime.now().subtract(const Duration(seconds: 30));
      expect(formatTimeAgo(dt), 'time_ago.just_now');
    });

    test('1 minute ago returns minute_ago key', () {
      final dt = DateTime.now().subtract(const Duration(minutes: 1));
      expect(formatTimeAgo(dt), 'time_ago.minute_ago');
    });

    test('multiple minutes ago returns minutes_ago key with n', () {
      final dt = DateTime.now().subtract(const Duration(minutes: 15));
      expect(formatTimeAgo(dt), 'time_ago.minutes_ago');
    });

    test('1 hour ago returns hour_ago key', () {
      final dt = DateTime.now().subtract(const Duration(hours: 1));
      expect(formatTimeAgo(dt), 'time_ago.hour_ago');
    });

    test('multiple hours ago returns hours_ago key', () {
      final dt = DateTime.now().subtract(const Duration(hours: 5));
      expect(formatTimeAgo(dt), 'time_ago.hours_ago');
    });

    test('1 day ago returns yesterday key', () {
      final dt = DateTime.now().subtract(const Duration(days: 1));
      expect(formatTimeAgo(dt), 'time_ago.yesterday');
    });

    test('multiple days ago returns days_ago key', () {
      final dt = DateTime.now().subtract(const Duration(days: 3));
      expect(formatTimeAgo(dt), 'time_ago.days_ago');
    });

    test('1 week ago returns week_ago key', () {
      final dt = DateTime.now().subtract(const Duration(days: 10));
      expect(formatTimeAgo(dt), 'time_ago.week_ago');
    });

    test('multiple weeks ago returns weeks_ago key', () {
      final dt = DateTime.now().subtract(const Duration(days: 21));
      expect(formatTimeAgo(dt), 'time_ago.weeks_ago');
    });

    test('1 month ago returns month_ago key', () {
      final dt = DateTime.now().subtract(const Duration(days: 35));
      expect(formatTimeAgo(dt), 'time_ago.month_ago');
    });

    test('multiple months ago returns months_ago key', () {
      final dt = DateTime.now().subtract(const Duration(days: 120));
      expect(formatTimeAgo(dt), 'time_ago.months_ago');
    });

    test('1 year ago returns year_ago key', () {
      final dt = DateTime.now().subtract(const Duration(days: 400));
      expect(formatTimeAgo(dt), 'time_ago.year_ago');
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

  group('formatMemberSince', () {
    test('NL locale returns formatted date', () {
      final dt = DateTime(2025, 6);
      final result = formatMemberSince(dt, locale: 'nl');
      expect(result, contains('2025'));
    });

    test('EN locale returns formatted date', () {
      final dt = DateTime(2025, 6);
      final result = formatMemberSince(dt, locale: 'en');
      expect(result, contains('2025'));
    });
  });
}
