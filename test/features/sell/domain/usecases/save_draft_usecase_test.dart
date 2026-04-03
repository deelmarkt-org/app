import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';
import 'package:deelmarkt/features/sell/domain/repositories/listing_creation_repository.dart';
import 'package:deelmarkt/features/sell/domain/usecases/save_draft_usecase.dart';

class _MockListingCreationRepository extends Mock
    implements ListingCreationRepository {}

void main() {
  late SaveDraftUseCase useCase;
  late _MockListingCreationRepository mockRepo;

  final testListing = ListingEntity(
    id: 'draft-001',
    title: 'My draft',
    description: '',
    priceInCents: 0,
    sellerId: 'user-001',
    sellerName: 'Jan de Vries',
    condition: ListingCondition.good,
    categoryId: '',
    imageUrls: const [],
    createdAt: DateTime(2026, 4),
    status: ListingStatus.draft,
  );

  const testState = ListingCreationState(
    imageFiles: ['photo1.jpg'],
    title: 'My draft',
    description: 'Partial description',
    priceInCents: 1000,
    categoryL2Id: 'cat-books',
    condition: ListingCondition.fair,
    location: '3011HE',
    shippingCarrier: ShippingCarrier.dhl,
    weightRange: WeightRange.twoToFive,
  );

  setUpAll(() {
    registerFallbackValue(ListingCondition.good);
    registerFallbackValue(ShippingCarrier.none);
    registerFallbackValue(WeightRange.zeroToTwo);
  });

  setUp(() {
    mockRepo = _MockListingCreationRepository();
    useCase = SaveDraftUseCase(mockRepo);
  });

  group('SaveDraftUseCase', () {
    test('delegates to repository.saveDraft with correct params', () async {
      when(
        () => mockRepo.saveDraft(
          title: any(named: 'title'),
          description: any(named: 'description'),
          priceInCents: any(named: 'priceInCents'),
          condition: any(named: 'condition'),
          categoryId: any(named: 'categoryId'),
          imagePaths: any(named: 'imagePaths'),
          location: any(named: 'location'),
          shippingCarrier: any(named: 'shippingCarrier'),
          weightRange: any(named: 'weightRange'),
        ),
      ).thenAnswer((_) async => testListing);

      final result = await useCase.call(state: testState);

      expect(result, testListing);
      verify(
        () => mockRepo.saveDraft(
          title: 'My draft',
          description: 'Partial description',
          priceInCents: 1000,
          condition: ListingCondition.fair,
          categoryId: 'cat-books',
          imagePaths: ['photo1.jpg'],
          location: '3011HE',
          shippingCarrier: ShippingCarrier.dhl,
          weightRange: WeightRange.twoToFive,
        ),
      ).called(1);
    });

    test('propagates repository exceptions', () async {
      when(
        () => mockRepo.saveDraft(
          title: any(named: 'title'),
          description: any(named: 'description'),
          priceInCents: any(named: 'priceInCents'),
          condition: any(named: 'condition'),
          categoryId: any(named: 'categoryId'),
          imagePaths: any(named: 'imagePaths'),
          location: any(named: 'location'),
          shippingCarrier: any(named: 'shippingCarrier'),
          weightRange: any(named: 'weightRange'),
        ),
      ).thenThrow(Exception('Disk full'));

      expect(() => useCase.call(state: testState), throwsA(isA<Exception>()));
    });
  });
}
