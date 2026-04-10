import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
// Hide gotrue.AuthException so it doesn't collide with our domain one.
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import 'package:deelmarkt/core/domain/entities/listing_entity.dart';
import 'package:deelmarkt/core/exceptions/app_exception.dart';
import 'package:deelmarkt/features/sell/data/services/listing_quality_score_service.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockFunctionsClient extends Mock implements FunctionsClient {}

void main() {
  late MockSupabaseClient client;
  late MockFunctionsClient functions;
  late ListingQualityScoreService service;

  // Canonical happy-path EF payload — mirrors the shape returned by
  // scoring_engine.ts for a perfect draft.
  const perfectResponse = <String, dynamic>{
    'score': 100,
    'can_publish': true,
    'breakdown': [
      {
        'name': 'sell.photos',
        'points': 25,
        'max_points': 25,
        'passed': true,
        'tip_key': null,
      },
      {
        'name': 'sell.title',
        'points': 15,
        'max_points': 15,
        'passed': true,
        'tip_key': null,
      },
      {
        'name': 'sell.description',
        'points': 20,
        'max_points': 20,
        'passed': true,
        'tip_key': null,
      },
      {
        'name': 'sell.price',
        'points': 15,
        'max_points': 15,
        'passed': true,
        'tip_key': null,
      },
      {
        'name': 'sell.category',
        'points': 15,
        'max_points': 15,
        'passed': true,
        'tip_key': null,
      },
      {
        'name': 'sell.condition',
        'points': 10,
        'max_points': 10,
        'passed': true,
        'tip_key': null,
      },
    ],
  };

  ListingCreationState draftState({
    List<String> imageFiles = const ['a.jpg', 'b.jpg', 'c.jpg'],
    String title = 'Great item for sale',
    String description = 'A detailed description with many words to pass',
    int priceInCents = 4500,
    String? categoryL2Id = 'cat-phones',
    ListingCondition? condition = ListingCondition.good,
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

  setUp(() {
    client = MockSupabaseClient();
    functions = MockFunctionsClient();
    when(() => client.functions).thenReturn(functions);
    service = ListingQualityScoreService(client);
  });

  group('ListingQualityScoreService.calculate — happy path', () {
    test('parses a perfect server response into a typed result', () async {
      when(
        () =>
            functions.invoke('listing-quality-score', body: any(named: 'body')),
      ).thenAnswer(
        (_) async => FunctionResponse(status: 200, data: perfectResponse),
      );

      final result = await service.calculate(draftState());

      expect(result.score, 100);
      expect(result.canPublish, true);
      expect(result.breakdown, hasLength(6));
      expect(result.breakdown.first.name, 'sell.photos');
      expect(result.breakdown.first.passed, true);
      expect(result.breakdown.first.tipKey, isNull);
    });

    test('sends the expected request body shape', () async {
      Map<String, dynamic>? capturedBody;
      when(() => functions.invoke(any(), body: any(named: 'body'))).thenAnswer((
        invocation,
      ) async {
        capturedBody = invocation.namedArguments[#body] as Map<String, dynamic>;
        return FunctionResponse(status: 200, data: perfectResponse);
      });

      await service.calculate(
        draftState(
          imageFiles: const ['a.jpg', 'b.jpg'],
          title: 'Pants',
          description: 'Nice',
          priceInCents: 1200,
          categoryL2Id: 'cat-pants',
          condition: ListingCondition.fair,
        ),
      );

      expect(capturedBody, isNotNull);
      expect(capturedBody!['photo_count'], 2);
      expect(capturedBody!['title'], 'Pants');
      expect(capturedBody!['description'], 'Nice');
      expect(capturedBody!['price_cents'], 1200);
      expect(capturedBody!['category_l2_id'], 'cat-pants');
      expect(capturedBody!['condition'], 'fair');
    });

    test('serialises nullable optionals as null when unset', () async {
      Map<String, dynamic>? capturedBody;
      when(() => functions.invoke(any(), body: any(named: 'body'))).thenAnswer((
        invocation,
      ) async {
        capturedBody = invocation.namedArguments[#body] as Map<String, dynamic>;
        return FunctionResponse(status: 200, data: perfectResponse);
      });

      await service.calculate(draftState(categoryL2Id: null, condition: null));

      expect(capturedBody!['category_l2_id'], isNull);
      expect(capturedBody!['condition'], isNull);
    });
  });

  // supabase_flutter's FunctionsClient throws FunctionException on any
  // non-2xx — it never returns a FunctionResponse with status >= 300.
  // Tests that simulate server errors must use thenThrow(FunctionException).
  group('ListingQualityScoreService.calculate — error paths', () {
    void arrangeFailure(int status, Object? details) {
      when(
        () =>
            functions.invoke('listing-quality-score', body: any(named: 'body')),
      ).thenThrow(FunctionException(status: status, details: details));
    }

    test(
      'maps 400 to ValidationException(error.quality_score.invalid_request)',
      () async {
        arrangeFailure(400, const {'error': 'schema mismatch'});

        await expectLater(
          service.calculate(draftState()),
          throwsA(
            isA<ValidationException>()
                .having(
                  (e) => e.messageKey,
                  'messageKey',
                  'error.quality_score.invalid_request',
                )
                .having(
                  (e) => e.debugMessage,
                  'debugMessage',
                  contains('schema mismatch'),
                ),
          ),
        );
      },
    );

    test('maps 500 to NetworkException(error.network)', () async {
      arrangeFailure(500, null);

      await expectLater(
        service.calculate(draftState()),
        throwsA(
          isA<NetworkException>().having(
            (e) => e.messageKey,
            'messageKey',
            'error.network',
          ),
        ),
      );
    });

    test('maps 503 to NetworkException(error.network)', () async {
      // listing-quality-score doesn't get a dedicated 503 l10n key
      // because it has no third-party deps — any 5xx is treated as a
      // transient transport failure.
      arrangeFailure(503, null);

      await expectLater(
        service.calculate(draftState()),
        throwsA(
          isA<NetworkException>().having(
            (e) => e.messageKey,
            'messageKey',
            'error.network',
          ),
        ),
      );
    });

    test('maps non-map 200 payload to NetworkException', () async {
      when(
        () =>
            functions.invoke('listing-quality-score', body: any(named: 'body')),
      ).thenAnswer(
        (_) async => FunctionResponse(status: 200, data: 'not a map'),
      );

      await expectLater(
        service.calculate(draftState()),
        throwsA(isA<NetworkException>()),
      );
    });

    test(
      'maps malformed 200 payload (FormatException) to NetworkException',
      () async {
        when(
          () => functions.invoke(
            'listing-quality-score',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 200,
            data: const {'score': 'oops', 'can_publish': true},
          ),
        );

        await expectLater(
          service.calculate(draftState()),
          throwsA(isA<NetworkException>()),
        );
      },
    );
  });
}
