import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';
import 'package:deelmarkt/features/sell/domain/usecases/calculate_quality_score_usecase.dart';

void main() {
  const useCase = CalculateQualityScoreUseCase();

  ListingCreationState buildState({
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

  /// Generates a description with the given word count.
  String wordsOf(int count) => List.filled(count, 'word').join(' ');

  group('CalculateQualityScoreUseCase', () {
    test('empty initial state yields score 0 and canPublish false', () {
      final result = useCase.call(ListingCreationState.initial());

      expect(result.score, 0);
      expect(result.canPublish, false);
      expect(result.breakdown.every((f) => !f.passed), true);
    });

    test('perfect state yields score 100 and canPublish true', () {
      final result = useCase.call(
        buildState(
          imageFiles: ['a.jpg', 'b.jpg', 'c.jpg'],
          title: 'Great item for sale', // 19 chars, within 10-60
          description: wordsOf(50),
          priceInCents: 4500,
          categoryL2Id: 'cat-phones',
          condition: ListingCondition.good,
        ),
      );

      expect(result.score, 100);
      expect(result.canPublish, true);
      expect(result.breakdown.every((f) => f.passed), true);
      expect(result.breakdown.every((f) => f.tipKey == null), true);
    });

    group('photos scoring', () {
      test('2 photos yields 0 points', () {
        final result = useCase.call(buildState(imageFiles: ['a.jpg', 'b.jpg']));
        final photos = result.breakdown.firstWhere(
          (f) => f.name == 'sell.photos',
        );
        expect(photos.points, 0);
        expect(photos.passed, false);
        expect(photos.tipKey, 'sell.tipMorePhotos');
      });

      test('3 photos yields 25 points', () {
        final result = useCase.call(
          buildState(imageFiles: ['a.jpg', 'b.jpg', 'c.jpg']),
        );
        final photos = result.breakdown.firstWhere(
          (f) => f.name == 'sell.photos',
        );
        expect(photos.points, 25);
        expect(photos.maxPoints, 25);
        expect(photos.passed, true);
        expect(photos.tipKey, isNull);
      });
    });

    group('title scoring', () {
      test('9 chars yields 0 points', () {
        final result = useCase.call(buildState(title: '123456789'));
        final title = result.breakdown.firstWhere(
          (f) => f.name == 'sell.title',
        );
        expect(title.points, 0);
        expect(title.passed, false);
        expect(title.tipKey, 'sell.titleTip');
      });

      test('10 chars yields 15 points', () {
        final result = useCase.call(buildState(title: '1234567890'));
        final title = result.breakdown.firstWhere(
          (f) => f.name == 'sell.title',
        );
        expect(title.points, 15);
        expect(title.passed, true);
      });

      test('60 chars yields 15 points', () {
        final result = useCase.call(buildState(title: 'A' * 60));
        final title = result.breakdown.firstWhere(
          (f) => f.name == 'sell.title',
        );
        expect(title.points, 15);
        expect(title.passed, true);
      });

      test('61 chars yields 0 points', () {
        final result = useCase.call(buildState(title: 'A' * 61));
        final title = result.breakdown.firstWhere(
          (f) => f.name == 'sell.title',
        );
        expect(title.points, 0);
        expect(title.passed, false);
      });
    });

    group('description scoring', () {
      test('49 words yields 0 points', () {
        final result = useCase.call(buildState(description: wordsOf(49)));
        final desc = result.breakdown.firstWhere(
          (f) => f.name == 'sell.description',
        );
        expect(desc.points, 0);
        expect(desc.passed, false);
        expect(desc.tipKey, 'sell.descriptionTip');
      });

      test('50 words yields 20 points', () {
        final result = useCase.call(buildState(description: wordsOf(50)));
        final desc = result.breakdown.firstWhere(
          (f) => f.name == 'sell.description',
        );
        expect(desc.points, 20);
        expect(desc.passed, true);
        expect(desc.tipKey, isNull);
      });
    });

    group('price scoring', () {
      test('0 cents yields 0 points', () {
        final result = useCase.call(buildState());
        final price = result.breakdown.firstWhere(
          (f) => f.name == 'sell.price',
        );
        expect(price.points, 0);
        expect(price.passed, false);
        expect(price.tipKey, 'sell.priceTip');
      });

      test('1 cent yields 15 points', () {
        final result = useCase.call(buildState(priceInCents: 1));
        final price = result.breakdown.firstWhere(
          (f) => f.name == 'sell.price',
        );
        expect(price.points, 15);
        expect(price.passed, true);
        expect(price.tipKey, isNull);
      });
    });

    group('category scoring', () {
      test('null categoryL2Id yields 0 points', () {
        final result = useCase.call(buildState());
        final cat = result.breakdown.firstWhere(
          (f) => f.name == 'sell.category',
        );
        expect(cat.points, 0);
        expect(cat.passed, false);
        expect(cat.tipKey, 'sell.categoryTip');
      });

      test('non-null categoryL2Id yields 15 points', () {
        final result = useCase.call(buildState(categoryL2Id: 'cat-phones'));
        final cat = result.breakdown.firstWhere(
          (f) => f.name == 'sell.category',
        );
        expect(cat.points, 15);
        expect(cat.passed, true);
        expect(cat.tipKey, isNull);
      });
    });

    group('condition scoring', () {
      test('null condition yields 0 points', () {
        final result = useCase.call(buildState());
        final cond = result.breakdown.firstWhere(
          (f) => f.name == 'sell.condition',
        );
        expect(cond.points, 0);
        expect(cond.passed, false);
        expect(cond.tipKey, 'sell.conditionTip');
      });

      test('any condition value yields 10 points', () {
        final result = useCase.call(
          buildState(condition: ListingCondition.fair),
        );
        final cond = result.breakdown.firstWhere(
          (f) => f.name == 'sell.condition',
        );
        expect(cond.points, 10);
        expect(cond.passed, true);
        expect(cond.tipKey, isNull);
      });
    });

    group('canPublish boundary', () {
      test('score 39 yields canPublish false', () {
        // photos(25) + title(0) + desc(0) + price(0) + cat(0) + cond(10) = 35
        // photos(25) + title(15) = 40, too high
        // price(15) + photos(25) = 40, too high
        // photos(25) + cond(10) = 35 → false
        final result = useCase.call(
          buildState(
            imageFiles: ['a.jpg', 'b.jpg', 'c.jpg'],
            condition: ListingCondition.good,
          ),
        );
        // score = 25 + 10 = 35
        expect(result.score, 35);
        expect(result.canPublish, false);
      });

      test('score 40 yields canPublish true', () {
        // photos(25) + title(15) = 40
        final result = useCase.call(
          buildState(
            imageFiles: ['a.jpg', 'b.jpg', 'c.jpg'],
            title: 'Ten chars!', // exactly 10 chars
          ),
        );
        expect(result.score, 40);
        expect(result.canPublish, true);
      });
    });
  });
}
