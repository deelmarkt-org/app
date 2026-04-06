import 'package:deelmarkt/core/utils/chat_date_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests the parts of [ChatDateFormatter] that do NOT require
/// EasyLocalization initialisation. The l10n-backed branches
/// (today / yesterday) are covered by widget tests.
void main() {
  group('ChatDateFormatter.bubbleTime', () {
    test('returns HH:mm for any DateTime', () {
      expect(
        ChatDateFormatter.bubbleTime(DateTime(2026, 3, 25, 14, 32)),
        '14:32',
      );
    });

    test('zero-pads single-digit hours and minutes', () {
      expect(
        ChatDateFormatter.bubbleTime(DateTime(2026, 3, 25, 9, 5)),
        '09:05',
      );
    });
  });

  group('ChatDateFormatter.daySeparator — non-l10n branches', () {
    final now = DateTime(2026, 3, 25, 15);

    test('3 days ago returns a non-empty weekday name', () {
      final label = ChatDateFormatter.daySeparator(
        DateTime(2026, 3, 22),
        now: now,
      );
      expect(label, isNotEmpty);
    });

    test('older than a week returns short date containing the year', () {
      final label = ChatDateFormatter.daySeparator(
        DateTime(2026, 2, 10),
        now: now,
      );
      expect(label, contains('2026'));
    });
  });

  group('ChatDateFormatter.relativeRowTimestamp — non-l10n branches', () {
    final now = DateTime(2026, 3, 25, 15);

    test('same day returns HH:mm', () {
      expect(
        ChatDateFormatter.relativeRowTimestamp(
          DateTime(2026, 3, 25, 14, 32),
          now: now,
        ),
        '14:32',
      );
    });

    test('older than a week returns numeric short date', () {
      final label = ChatDateFormatter.relativeRowTimestamp(
        DateTime(2026, 2, 10),
        now: now,
      );
      // yMd format contains year digits.
      expect(label, contains('2026'));
    });
  });
}
