import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:deelmarkt/core/utils/time_ago.dart';

// In test environments without easy_localization setup, .tr() returns the
// l10n key path (e.g. 'timeAgo.justNow'). Tests verify the correct key
// is selected rather than the translated string value.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('nl');
    await initializeDateFormatting('en');
  });

  group('formatTimeAgo key selection', () {
    test('seconds ago returns justNow key', () {
      final dt = DateTime.now().subtract(const Duration(seconds: 30));
      expect(formatTimeAgo(dt), 'timeAgo.justNow');
    });

    test('1 minute ago returns minuteAgo key', () {
      final dt = DateTime.now().subtract(const Duration(minutes: 1));
      expect(formatTimeAgo(dt), 'timeAgo.minuteAgo');
    });

    test('multiple minutes ago returns minutesAgo key with n', () {
      final dt = DateTime.now().subtract(const Duration(minutes: 15));
      expect(formatTimeAgo(dt), 'timeAgo.minutesAgo');
    });

    test('1 hour ago returns hourAgo key', () {
      final dt = DateTime.now().subtract(const Duration(hours: 1));
      expect(formatTimeAgo(dt), 'timeAgo.hourAgo');
    });

    test('multiple hours ago returns hoursAgo key', () {
      final dt = DateTime.now().subtract(const Duration(hours: 5));
      expect(formatTimeAgo(dt), 'timeAgo.hoursAgo');
    });

    test('1 day ago returns yesterday key', () {
      final dt = DateTime.now().subtract(const Duration(days: 1));
      expect(formatTimeAgo(dt), 'timeAgo.yesterday');
    });

    test('multiple days ago returns daysAgo key', () {
      final dt = DateTime.now().subtract(const Duration(days: 3));
      expect(formatTimeAgo(dt), 'timeAgo.daysAgo');
    });

    test('1 week ago returns weekAgo key', () {
      final dt = DateTime.now().subtract(const Duration(days: 10));
      expect(formatTimeAgo(dt), 'timeAgo.weekAgo');
    });

    test('multiple weeks ago returns weeksAgo key', () {
      final dt = DateTime.now().subtract(const Duration(days: 21));
      expect(formatTimeAgo(dt), 'timeAgo.weeksAgo');
    });

    test('1 month ago returns monthAgo key', () {
      final dt = DateTime.now().subtract(const Duration(days: 35));
      expect(formatTimeAgo(dt), 'timeAgo.monthAgo');
    });

    test('multiple months ago returns monthsAgo key', () {
      final dt = DateTime.now().subtract(const Duration(days: 120));
      expect(formatTimeAgo(dt), 'timeAgo.monthsAgo');
    });

    test('1 year ago returns yearAgo key', () {
      final dt = DateTime.now().subtract(const Duration(days: 400));
      expect(formatTimeAgo(dt), 'timeAgo.yearAgo');
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
      final result = formatMemberSince(dt);
      expect(result, contains('2025'));
    });

    test('EN locale returns formatted date', () {
      final dt = DateTime(2025, 6);
      final result = formatMemberSince(dt, locale: 'en');
      expect(result, contains('2025'));
    });
  });
}
