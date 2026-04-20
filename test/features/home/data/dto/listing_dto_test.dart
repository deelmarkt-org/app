import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/home/data/dto/listing_dto.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';

void main() {
  group('ListingDto', () {
    final sampleJson = {
      'id': 'listing-001',
      'title': 'iPhone 15 Pro',
      'description': 'Barely used, with original box',
      'price_cents': 89900,
      'seller_id': 'user-001',
      'seller_name': 'Jan de Vries',
      'condition': 'like_new',
      'category_id': 'c1000000-0000-0000-0000-000000000001',
      'image_urls': [
        'https://example.com/img1.jpg',
        'https://example.com/img2.jpg',
      ],
      'location': 'Amsterdam',
      'is_favourited': true,
      'quality_score': 85,
      'created_at': '2026-03-25T10:00:00Z',
    };

    test('fromJson parses all fields correctly', () {
      final entity = ListingDto.fromJson(sampleJson);

      expect(entity.id, 'listing-001');
      expect(entity.title, 'iPhone 15 Pro');
      expect(entity.priceInCents, 89900);
      expect(entity.sellerName, 'Jan de Vries');
      expect(entity.condition, ListingCondition.likeNew);
      expect(entity.imageUrls, hasLength(2));
      expect(entity.isFavourited, true);
      expect(entity.qualityScore, 85);
    });

    test('fromJson handles missing optional fields', () {
      final minimalJson = {
        'id': 'listing-002',
        'title': 'Fiets',
        'description': 'Goede tweedehands fiets',
        'price_cents': 15000,
        'seller_id': 'user-002',
        'condition': 'good',
        'category_id': 'c1000000-0000-0000-0000-000000000004',
        'created_at': '2026-03-25T10:00:00Z',
      };

      final entity = ListingDto.fromJson(minimalJson);

      expect(entity.sellerName, 'Verkoper');
      expect(entity.imageUrls, isEmpty);
      expect(entity.isFavourited, false);
      expect(entity.qualityScore, isNull);
      expect(entity.location, isNull);
      expect(entity.distanceKm, isNull);
    });

    test('toJson produces writable fields only', () {
      final entity = ListingDto.fromJson(sampleJson);
      final json = ListingDto.toJson(entity);

      expect(json['title'], 'iPhone 15 Pro');
      expect(json['price_cents'], 89900);
      expect(json['condition'], 'like_new');
      expect(json.containsKey('id'), false);
      expect(json.containsKey('seller_name'), false);
      expect(json.containsKey('is_favourited'), false);
    });

    test('fromJsonList parses multiple items', () {
      final list = ListingDto.fromJsonList([sampleJson, sampleJson]);

      expect(list, hasLength(2));
      expect(list.first.id, 'listing-001');
    });

    test('fromJsonList skips non-Map entries', () {
      final list = ListingDto.fromJsonList([sampleJson, 'invalid', 42, null]);
      expect(list, hasLength(1));
    });

    test('fromJson throws FormatException on missing required fields', () {
      expect(() => ListingDto.fromJson({}), throwsFormatException);
      expect(
        () => ListingDto.fromJson({'id': 'x', 'title': 'x'}),
        throwsFormatException,
      );
    });

    test('fromJson handles null optional fields gracefully', () {
      final json = {
        'id': 'listing-003',
        'title': 'Test',
        'description': 'Test description',
        'price_cents': 100,
        'created_at': '2026-01-01T00:00:00Z',
        'seller_id': null,
        'seller_name': null,
        'condition': null,
        'category_id': null,
        'image_urls': null,
        'is_favourited': null,
      };
      final entity = ListingDto.fromJson(json);
      expect(entity.sellerId, '');
      expect(entity.sellerName, 'Verkoper');
      expect(entity.condition, ListingCondition.good);
      expect(entity.categoryId, '');
      expect(entity.imageUrls, isEmpty);
      expect(entity.isFavourited, false);
    });

    test('fromJson uses DateTime.now on invalid date', () {
      final json = {
        'id': 'listing-004',
        'title': 'Test',
        'description': 'Test desc',
        'price_cents': 100,
        'created_at': 'not-a-date',
      };
      final entity = ListingDto.fromJson(json);
      expect(entity.createdAt.year, DateTime.now().year);
    });

    test('fromJson handles unknown condition gracefully', () {
      final json = {...sampleJson, 'condition': 'future_condition'};
      final entity = ListingDto.fromJson(json);
      expect(entity.condition, ListingCondition.good);
    });

    group('escrow_eligible parse (ADR-023, fail-closed)', () {
      test('maps escrow_eligible=true to isEscrowAvailable=true', () {
        final entity = ListingDto.fromJson({
          ...sampleJson,
          'escrow_eligible': true,
        });
        expect(entity.isEscrowAvailable, isTrue);
      });

      test('maps escrow_eligible=false to isEscrowAvailable=false', () {
        final entity = ListingDto.fromJson({
          ...sampleJson,
          'escrow_eligible': false,
        });
        expect(entity.isEscrowAvailable, isFalse);
      });

      test('missing escrow_eligible key → false (fail-closed)', () {
        final entity = ListingDto.fromJson(sampleJson);
        expect(entity.isEscrowAvailable, isFalse);
      });

      test('escrow_eligible=null → false (fail-closed)', () {
        final entity = ListingDto.fromJson({
          ...sampleJson,
          'escrow_eligible': null,
        });
        expect(entity.isEscrowAvailable, isFalse);
      });

      test('escrow_eligible=non-bool (e.g. "true" string) → false', () {
        final entity = ListingDto.fromJson({
          ...sampleJson,
          'escrow_eligible': 'true',
        });
        expect(entity.isEscrowAvailable, isFalse);
      });

      test('escrow_eligible=1 (integer truthy) → false (strict bool-only)', () {
        // Supabase REST can serialise booleans as integers in rare RPC
        // projections; the DTO must not coerce 1 to true — that would
        // bypass the server-authoritative boolean contract.
        final entity = ListingDto.fromJson({
          ...sampleJson,
          'escrow_eligible': 1,
        });
        expect(entity.isEscrowAvailable, isFalse);
      });

      test('toJson does NOT include escrow_eligible (server-owned)', () {
        final entity = ListingDto.fromJson({
          ...sampleJson,
          'escrow_eligible': true,
        });
        final json = ListingDto.toJson(entity);
        expect(json.containsKey('escrow_eligible'), isFalse);
      });
    });
  });
}
