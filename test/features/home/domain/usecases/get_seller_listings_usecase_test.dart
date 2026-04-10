import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/home/domain/repositories/listing_repository.dart';
import 'package:deelmarkt/features/home/domain/usecases/get_seller_listings_usecase.dart';

class _FakeListingRepository implements ListingRepository {
  final List<ListingEntity> _userListings;

  _FakeListingRepository(this._userListings);

  @override
  Future<List<ListingEntity>> getByUserId(
    String userId, {
    int limit = 10,
    String? cursor,
  }) async => _userListings.take(limit).toList();

  @override
  Future<List<ListingEntity>> getRecent({int limit = 20}) async => [];

  @override
  Future<List<ListingEntity>> getNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 25,
    int limit = 20,
  }) async => [];

  @override
  Future<ListingEntity?> getById(String id) async => null;

  @override
  Future<ListingSearchResult> search({
    required String query,
    String? categoryId,
    List<String>? categoryIds,
    int? minPriceCents,
    int? maxPriceCents,
    ListingCondition? condition,
    String? sortBy,
    bool ascending = false,
    int offset = 0,
    int limit = 20,
  }) async =>
      const ListingSearchResult(listings: [], total: 0, offset: 0, limit: 20);

  @override
  Future<ListingEntity> toggleFavourite(String listingId) =>
      throw UnimplementedError();

  @override
  Future<List<ListingEntity>> getFavourites() async => [];
}

ListingEntity _testListing(String id) => ListingEntity(
  id: id,
  title: 'Item $id',
  description: 'Description',
  priceInCents: 1000,
  sellerId: 'seller-1',
  sellerName: 'Seller',
  condition: ListingCondition.good,
  categoryId: 'cat-1',
  imageUrls: const [],
  createdAt: DateTime(2026),
);

void main() {
  group('GetSellerListingsUseCase', () {
    test('returns listings from repository', () async {
      final listings = [_testListing('1'), _testListing('2')];
      final repo = _FakeListingRepository(listings);
      final useCase = GetSellerListingsUseCase(repo);

      final result = await useCase.call('seller-1');

      expect(result.length, 2);
      expect(result.first.id, '1');
    });

    test('returns empty list when no listings', () async {
      final repo = _FakeListingRepository([]);
      final useCase = GetSellerListingsUseCase(repo);

      final result = await useCase.call('seller-1');

      expect(result, isEmpty);
    });

    test('respects limit parameter', () async {
      final listings = List.generate(30, (i) => _testListing('$i'));
      final repo = _FakeListingRepository(listings);
      final useCase = GetSellerListingsUseCase(repo);

      final result = await useCase.call('seller-1', limit: 5);

      expect(result.length, 5);
    });
  });
}
