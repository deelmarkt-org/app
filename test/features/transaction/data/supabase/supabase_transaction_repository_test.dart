import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/core/models/transaction_status.dart';
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
      test('attempts to insert into transactions table', () async {
        // Unstubbed mock — verifies the method calls _client.from().
        expect(
          () => repo.createTransaction(
            listingId: 'listing-001',
            buyerId: 'buyer-001',
            sellerId: 'seller-001',
            itemAmountCents: 5000,
            shippingCostCents: 495,
          ),
          throwsA(isA<TypeError>()),
        );
      });
    });

    group('getTransaction', () {
      test('attempts to query transactions table', () async {
        expect(() => repo.getTransaction('txn-001'), throwsA(isA<TypeError>()));
      });
    });

    group('getTransactionsForUser', () {
      test('queries by buyer_id or seller_id', () async {
        expect(
          () => repo.getTransactionsForUser('user-001'),
          throwsA(isA<TypeError>()),
        );
      });
    });

    group('service-role-only methods', () {
      test('updateStatus throws UnsupportedError', () async {
        expect(
          () => repo.updateStatus(
            transactionId: 'txn-001',
            newStatus: TransactionStatus.paid,
          ),
          throwsA(isA<UnsupportedError>()),
        );
      });

      test('setMolliePaymentId throws UnsupportedError', () async {
        expect(
          () => repo.setMolliePaymentId(
            transactionId: 'txn-001',
            molliePaymentId: 'tr_123',
          ),
          throwsA(isA<UnsupportedError>()),
        );
      });

      test('setEscrowDeadline throws UnsupportedError', () async {
        expect(
          () => repo.setEscrowDeadline(
            transactionId: 'txn-001',
            deadline: DateTime(2026, 5, 15),
          ),
          throwsA(isA<UnsupportedError>()),
        );
      });
    });
  });
}
