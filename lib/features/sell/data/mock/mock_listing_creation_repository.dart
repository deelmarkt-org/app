import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:deelmarkt/core/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';
import 'package:deelmarkt/features/sell/domain/repositories/listing_creation_repository.dart';

/// Mock listing creation repository — simulates backend for development.
///
/// Swapped for SupabaseListingCreationRepository in Phase 4.
/// Guarded by [kReleaseMode] — asserts in release builds.
class MockListingCreationRepository implements ListingCreationRepository {
  MockListingCreationRepository() {
    assert(
      !kReleaseMode,
      'MockListingCreationRepository must not be used in release builds',
    );
  }

  static final _random = Random();

  @override
  Future<ListingEntity> create({
    required String title,
    required String description,
    required int priceInCents,
    required ListingCondition condition,
    required String categoryId,
    required List<String> imagePaths,
    String? location,
    ShippingCarrier shippingCarrier = ShippingCarrier.none,
    WeightRange? weightRange,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    return ListingEntity(
      id: 'listing-${_random.nextInt(99999)}',
      title: (title),
      description: (description),
      priceInCents: priceInCents,
      sellerId: 'current-user',
      sellerName: 'Test Seller',
      condition: condition,
      categoryId: categoryId,
      imageUrls:
          imagePaths
              .map((path) => 'https://cdn.deelmarkt.nl/images/$path')
              .toList(),
      location: location,
      // ignore: avoid_redundant_argument_values
      status: ListingStatus.active, // explicit: create always publishes
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<ListingEntity> saveDraft({
    required String title,
    String description = '',
    int priceInCents = 0,
    ListingCondition? condition,
    String? categoryId,
    List<String> imagePaths = const [],
    String? location,
    ShippingCarrier shippingCarrier = ShippingCarrier.none,
    WeightRange? weightRange,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    return ListingEntity(
      id: 'listing-${_random.nextInt(99999)}',
      title: (title.isEmpty ? 'Draft' : title),
      description: (description),
      priceInCents: priceInCents,
      sellerId: 'current-user',
      sellerName: 'Test Seller',
      condition: condition ?? ListingCondition.good,
      categoryId: categoryId ?? 'cat-uncategorised',
      imageUrls:
          imagePaths
              .map((path) => 'https://cdn.deelmarkt.nl/images/$path')
              .toList(),
      location: location,
      status: ListingStatus.draft,
      createdAt: DateTime.now(),
    );
  }

  // TODO(R-27): Server-side sanitization is required in the real
  // SupabaseListingCreationRepository / Edge Function. This mock
  // intentionally does NOT sanitize to avoid a false sense of security.
  // The Supabase implementation must strip HTML tags and validate
  // input lengths before persisting to the database.
}
