import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/models/transaction_status.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/transaction/data/mock/mock_transaction_repository.dart';
import 'package:deelmarkt/features/transaction/presentation/transaction_detail_notifier.dart';

void main() {
  group('transactionDetailProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(
            MockTransactionRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);
    });

    test('returns transaction for known ID', () async {
      final txn = await container.read(
        transactionDetailProvider('txn-001').future,
      );

      expect(txn.id, 'txn-001');
      expect(txn.status, TransactionStatus.released);
    });

    test('throws for unknown ID', () async {
      expect(
        () => container.read(transactionDetailProvider('nonexistent').future),
        throwsA(isA<Exception>()),
      );
    });
  });
}
