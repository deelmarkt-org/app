import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:deelmarkt/core/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';
import 'package:deelmarkt/features/sell/domain/repositories/listing_creation_repository.dart';
import 'package:deelmarkt/features/sell/domain/usecases/create_listing_usecase.dart';

class _MockListingCreationRepository extends Mock
    implements ListingCreationRepository {}

void main() {
  late CreateListingUseCase useCase;
  late _MockListingCreationRepository mockRepo;

  final testListing = ListingEntity(
    id: 'listing-001',
    title: 'Vintage chair for sale',
    description: 'A beautiful vintage chair in great condition',
    priceInCents: 4500,
    sellerId: 'user-001',
    sellerName: 'Jan de Vries',
    condition: ListingCondition.good,
    categoryId: 'cat-furniture',
    imageUrls: const ['https://example.com/img1.jpg'],
    createdAt: DateTime(2026, 4),
  );

  const testState = ListingCreationState(
    imageFiles: ['photo1.jpg', 'photo2.jpg', 'photo3.jpg'],
    title: 'Vintage chair for sale',
    description: 'A beautiful vintage chair in great condition',
    priceInCents: 4500,
    categoryL2Id: 'cat-furniture',
    condition: ListingCondition.good,
    location: '1012AB',
    shippingCarrier: ShippingCarrier.postnl,
    weightRange: WeightRange.zeroToTwo,
  );

  setUpAll(() {
    registerFallbackValue(ListingCondition.good);
    registerFallbackValue(ShippingCarrier.none);
    registerFallbackValue(WeightRange.zeroToTwo);
  });

  setUp(() {
    mockRepo = _MockListingCreationRepository();
    useCase = CreateListingUseCase(mockRepo);
  });

  group('CreateListingUseCase', () {
    test('delegates to repository.create with correct params', () async {
      when(
        () => mockRepo.create(
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
        () => mockRepo.create(
          title: 'Vintage chair for sale',
          description: 'A beautiful vintage chair in great condition',
          priceInCents: 4500,
          condition: ListingCondition.good,
          categoryId: 'cat-furniture',
          imagePaths: ['photo1.jpg', 'photo2.jpg', 'photo3.jpg'],
          location: '1012AB',
          shippingCarrier: ShippingCarrier.postnl,
          weightRange: WeightRange.zeroToTwo,
        ),
      ).called(1);
    });

    test('propagates repository exceptions', () async {
      when(
        () => mockRepo.create(
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
      ).thenThrow(Exception('Network error'));

      expect(() => useCase.call(state: testState), throwsA(isA<Exception>()));
    });
  });
}
