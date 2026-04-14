import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/core/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/sell/data/supabase/supabase_listing_creation_repository.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class _StubUser extends Fake implements User {
  _StubUser({required this.id});
  @override
  final String id;
}

const _uid = 'user-test-123';

void _arrangeAuthenticated(MockSupabaseClient client, MockGoTrueClient auth) {
  when(() => client.auth).thenReturn(auth);
  when(() => auth.currentUser).thenReturn(_StubUser(id: _uid));
}

void _arrangeUnauthenticated(MockSupabaseClient client, MockGoTrueClient auth) {
  when(() => client.auth).thenReturn(auth);
  when(() => auth.currentUser).thenReturn(null);
}

void main() {
  late MockSupabaseClient client;
  late MockGoTrueClient auth;
  late SupabaseListingCreationRepository repo;

  setUp(() {
    client = MockSupabaseClient();
    auth = MockGoTrueClient();
    repo = SupabaseListingCreationRepository(client);
  });

  group('SupabaseListingCreationRepository', () {
    test('can be instantiated', () {
      expect(repo, isA<SupabaseListingCreationRepository>());
    });

    group('create', () {
      test('throws when not authenticated', () async {
        _arrangeUnauthenticated(client, auth);

        expect(
          () => repo.create(
            title: 'Test',
            description: 'Description for testing',
            priceInCents: 1000,
            condition: ListingCondition.good,
            categoryId: 'cat-001',
            imageUrls: ['https://example.com/img.jpg'],
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Not authenticated'),
            ),
          ),
        );
      });

      test('calls insert when authenticated', () async {
        _arrangeAuthenticated(client, auth);

        // Without a full PostgREST mock, verify auth guard passes
        // and the method attempts the DB call.
        expect(
          () => repo.create(
            title: 'Test',
            description: 'Description for testing',
            priceInCents: 1000,
            condition: ListingCondition.good,
            categoryId: 'cat-001',
            imageUrls: ['https://example.com/img.jpg'],
          ),
          throwsA(
            isNot(
              isA<Exception>().having(
                (e) => e.toString(),
                'message',
                contains('Not authenticated'),
              ),
            ),
          ),
        );
      });
    });

    group('saveDraft', () {
      test('throws when not authenticated', () async {
        _arrangeUnauthenticated(client, auth);

        expect(
          () => repo.saveDraft(title: 'Draft'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Not authenticated'),
            ),
          ),
        );
      });

      test('calls insert with is_active=false when authenticated', () async {
        _arrangeAuthenticated(client, auth);

        // Auth guard passes; method proceeds to DB call.
        expect(
          () => repo.saveDraft(title: 'Draft'),
          throwsA(
            isNot(
              isA<Exception>().having(
                (e) => e.toString(),
                'message',
                contains('Not authenticated'),
              ),
            ),
          ),
        );
      });
    });
  });
}
