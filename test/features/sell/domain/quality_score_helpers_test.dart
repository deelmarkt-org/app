import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/constants.dart';
import 'package:deelmarkt/core/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';
import 'package:deelmarkt/features/sell/domain/quality_score_helpers.dart';

void main() {
  group('qualityWordCount', () {
    test('returns zero for empty and whitespace-only input', () {
      expect(qualityWordCount(''), 0);
      expect(qualityWordCount('   \t\n '), 0);
    });

    test('collapses multiple whitespace characters between words', () {
      expect(qualityWordCount('hello   world'), 2);
      expect(qualityWordCount('a\tb\nc'), 3);
    });

    test('ignores leading and trailing whitespace', () {
      expect(qualityWordCount('  hello world  '), 2);
    });
  });

  group('qualityField', () {
    test('passing field earns max points and has no tip key', () {
      final field = qualityField('sell.photos', true, 25, 'sell.tipMorePhotos');
      expect(field.name, 'sell.photos');
      expect(field.points, 25);
      expect(field.maxPoints, 25);
      expect(field.passed, true);
      expect(field.tipKey, isNull);
    });

    test('failing field earns 0 points and exposes the tip key', () {
      final field = qualityField(
        'sell.photos',
        false,
        25,
        'sell.tipMorePhotos',
      );
      expect(field.points, 0);
      expect(field.maxPoints, 25);
      expect(field.passed, false);
      expect(field.tipKey, 'sell.tipMorePhotos');
    });
  });

  group('buildQualityBreakdown', () {
    // Reusable builder so each test only needs to override the field it's
    // exercising. Mirrors the pattern in calculate_quality_score_usecase_test.
    ListingCreationState stateWith({
      List<String> imageFiles = const [],
      String title = '',
      String description = '',
      int priceInCents = 0,
      String? categoryL2Id,
      ListingCondition? condition,
    }) {
      return ListingCreationState(
        imageFiles: imageFiles,
        title: title,
        description: description,
        priceInCents: priceInCents,
        categoryL2Id: categoryL2Id,
        condition: condition,
      );
    }

    test('returns six fields in the canonical order shared with the EF', () {
      final breakdown = buildQualityBreakdown(ListingCreationState.initial());
      expect(breakdown.map((f) => f.name).toList(), const [
        'sell.photos',
        'sell.title',
        'sell.description',
        'sell.price',
        'sell.category',
        'sell.condition',
      ]);
    });

    test('field max-points map exactly to ListingQualityThresholds', () {
      // Enforces parity with the constants so a rename or reorder in
      // ListingQualityThresholds surfaces here rather than silently in
      // production scoring.
      final breakdown = buildQualityBreakdown(ListingCreationState.initial());
      final byName = {for (final f in breakdown) f.name: f.maxPoints};
      expect(byName['sell.photos'], ListingQualityThresholds.photosWeight);
      expect(byName['sell.title'], ListingQualityThresholds.titleWeight);
      expect(
        byName['sell.description'],
        ListingQualityThresholds.descriptionWeight,
      );
      expect(byName['sell.price'], ListingQualityThresholds.priceWeight);
      expect(byName['sell.category'], ListingQualityThresholds.categoryWeight);
      expect(
        byName['sell.condition'],
        ListingQualityThresholds.conditionWeight,
      );
    });

    test('initial state marks every field as failed', () {
      final breakdown = buildQualityBreakdown(ListingCreationState.initial());
      expect(breakdown.every((f) => !f.passed), true);
      expect(breakdown.every((f) => f.points == 0), true);
      expect(breakdown.every((f) => f.tipKey != null), true);
    });

    test('complete state marks every field as passed', () {
      final breakdown = buildQualityBreakdown(
        stateWith(
          imageFiles: const ['a.jpg', 'b.jpg', 'c.jpg'],
          title: 'Great item for sale',
          description: List.filled(50, 'word').join(' '),
          priceInCents: 4500,
          categoryL2Id: 'cat-phones',
          condition: ListingCondition.good,
        ),
      );
      expect(breakdown.every((f) => f.passed), true);
      expect(breakdown.every((f) => f.tipKey == null), true);
      final total = breakdown.fold<int>(0, (s, f) => s + f.points);
      expect(total, 100);
    });

    test('title exactly at the lower boundary passes', () {
      final breakdown = buildQualityBreakdown(
        stateWith(title: '1234567890'), // 10 chars == minTitleLength
      );
      final title = breakdown.firstWhere((f) => f.name == 'sell.title');
      expect(title.passed, true);
    });

    test('title one character over the upper boundary fails', () {
      final breakdown = buildQualityBreakdown(
        stateWith(title: 'A' * 61), // 61 > maxTitleLength (60)
      );
      final title = breakdown.firstWhere((f) => f.name == 'sell.title');
      expect(title.passed, false);
    });
  });
}
