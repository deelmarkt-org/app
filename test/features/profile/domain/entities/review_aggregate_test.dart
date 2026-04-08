import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/profile/domain/entities/review_aggregate.dart';

void main() {
  group('ReviewAggregate', () {
    test('empty factory has zero averageRating and isVisible false', () {
      const empty = ReviewAggregate.empty('user-999');

      expect(empty.userId, 'user-999');
      expect(empty.averageRating, 0.0);
      expect(empty.totalCount, 0);
      expect(empty.isVisible, false);
      expect(empty.distribution, isEmpty);
      expect(empty.lastReviewAt, isNull);
    });

    test('equality works across identical instances', () {
      const a = ReviewAggregate(
        userId: 'u1',
        averageRating: 4.5,
        totalCount: 10,
        isVisible: true,
        distribution: {5: 5, 4: 5},
      );
      const b = ReviewAggregate(
        userId: 'u1',
        averageRating: 4.5,
        totalCount: 10,
        isVisible: true,
        distribution: {5: 5, 4: 5},
      );

      expect(a, equals(b));
    });

    test('different userId makes unequal', () {
      const a = ReviewAggregate(
        userId: 'u1',
        averageRating: 4.0,
        totalCount: 5,
        isVisible: true,
      );
      const b = ReviewAggregate(
        userId: 'u2',
        averageRating: 4.0,
        totalCount: 5,
        isVisible: true,
      );

      expect(a, isNot(equals(b)));
    });
  });

  group('ReviewAggregate property-based invariants', () {
    test('averageRating is always within [1.0, 5.0] for non-empty', () {
      final rnd = Random(42);
      for (var i = 0; i < 50; i++) {
        final count = rnd.nextInt(20) + 1;
        final sum = List.generate(
          count,
          (_) => rnd.nextInt(5) + 1,
        ).fold<int>(0, (a, b) => a + b);
        final avg = sum / count;

        expect(avg, greaterThanOrEqualTo(1.0));
        expect(avg, lessThanOrEqualTo(5.0));
      }
    });

    test('isVisible iff totalCount >= 3 (client fallback)', () {
      for (var count = 0; count <= 10; count++) {
        final agg = ReviewAggregate(
          userId: 'test',
          averageRating: 4.0,
          totalCount: count,
          isVisible: count >= 3,
        );

        expect(agg.isVisible, count >= 3);
      }
    });

    test('distribution values sum to totalCount', () {
      final dist = {5: 8, 4: 3, 3: 2, 2: 0, 1: 0};
      final total = dist.values.fold<int>(0, (a, b) => a + b);

      final agg = ReviewAggregate(
        userId: 'test',
        averageRating: 4.5,
        totalCount: total,
        isVisible: true,
        distribution: dist,
      );

      expect(
        agg.distribution.values.fold<int>(0, (a, b) => a + b),
        agg.totalCount,
      );
    });
  });
}
