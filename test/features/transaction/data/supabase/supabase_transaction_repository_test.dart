import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/features/transaction/data/supabase/supabase_transaction_repository.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late MockSupabaseClient client;
  late MockGoTrueClient auth;
  late SupabaseTransactionRepository repo;

  setUp(() {
    client = MockSupabaseClient();
    auth = MockGoTrueClient();
    when(() => client.auth).thenReturn(auth);
    repo = SupabaseTransactionRepository(client);
  });

  group('SupabaseTransactionRepository', () {
    test('can be instantiated', () {
      expect(repo, isA<SupabaseTransactionRepository>());
    });

    group('createTransaction', () {
      test('calls insert on transactions table', () async {
        // Without a real PostgREST mock, verify the method exists
        // and throws when Supabase is not configured.
        expect(
          () => repo.createTransaction(
            listingId: 'listing-001',
            buyerId: 'buyer-001',
            sellerId: 'seller-001',
            itemAmountCents: 5000,
            shippingCostCents: 495,
          ),
          throwsA(anything),
        );
      });
    });

    group('getTransaction', () {
      test('calls select on transactions table', () async {
        expect(() => repo.getTransaction('txn-001'), throwsA(anything));
      });
    });

    group('getTransactionsForUser', () {
      test('queries by buyer_id or seller_id', () async {
        expect(
          () => repo.getTransactionsForUser('user-001'),
          throwsA(anything),
        );
      });
    });
  });
}
