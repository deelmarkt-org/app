import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/profile/domain/entities/user_entity.dart';

void main() {
  group('BadgeType', () {
    group('toDbList', () {
      test('converts all badge types to string names', () {
        final badges = [
          BadgeType.emailVerified,
          BadgeType.phoneVerified,
          BadgeType.idVerified,
        ];

        final result = BadgeType.toDbList(badges);

        expect(result, ['emailVerified', 'phoneVerified', 'idVerified']);
      });

      test('returns empty list for empty input', () {
        expect(BadgeType.toDbList([]), isEmpty);
      });

      test('converts all 7 badge types', () {
        final result = BadgeType.toDbList(BadgeType.values);

        expect(result, [
          'emailVerified',
          'phoneVerified',
          'idVerified',
          'trustedSeller',
          'fastResponder',
          'topRated',
          'newUser',
        ]);
      });
    });

    group('fromDbList', () {
      test('parses valid badge strings', () {
        final result = BadgeType.fromDbList([
          'emailVerified',
          'trustedSeller',
          'fastResponder',
        ]);

        expect(result, [
          BadgeType.emailVerified,
          BadgeType.trustedSeller,
          BadgeType.fastResponder,
        ]);
      });

      test('skips unknown values (forward-compatible)', () {
        final result = BadgeType.fromDbList([
          'emailVerified',
          'unknownBadge',
          'phoneVerified',
          'futureBadge',
        ]);

        expect(result, [BadgeType.emailVerified, BadgeType.phoneVerified]);
      });

      test('handles empty list', () {
        expect(BadgeType.fromDbList([]), isEmpty);
      });

      test('handles non-string values in dynamic list', () {
        final result = BadgeType.fromDbList([
          'emailVerified',
          42,
          null,
          true,
          'phoneVerified',
        ]);

        expect(result, [BadgeType.emailVerified, BadgeType.phoneVerified]);
      });

      test('roundtrip: toDbList then fromDbList', () {
        final original = [
          BadgeType.emailVerified,
          BadgeType.idVerified,
          BadgeType.topRated,
        ];

        final roundtripped = BadgeType.fromDbList(BadgeType.toDbList(original));

        expect(roundtripped, original);
      });
    });
  });
}
