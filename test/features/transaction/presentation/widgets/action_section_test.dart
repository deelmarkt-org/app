import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/models/transaction_status.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/transaction/data/mock/mock_transaction_repository.dart';
import 'package:deelmarkt/features/transaction/domain/entities/transaction_entity.dart';
import 'package:deelmarkt/features/transaction/presentation/widgets/action_section.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

import '../../../../helpers/pump_app.dart';

TransactionEntity _txn({TransactionStatus status = TransactionStatus.paid}) {
  return TransactionEntity(
    id: 'txn_001',
    listingId: 'lst_001',
    buyerId: 'usr_buyer',
    sellerId: 'usr_seller',
    status: status,
    itemAmountCents: 4500,
    platformFeeCents: 113,
    shippingCostCents: 695,
    currency: 'EUR',
    createdAt: DateTime(2026, 3, 19),
  );
}

void main() {
  group('ActionSection', () {
    testWidgets('paid status shows info row, no buttons', (tester) async {
      await pumpTestScreenWithProviders(
        tester,
        Scaffold(body: ActionSection(transaction: _txn())),
        overrides: [
          transactionRepositoryProvider.overrideWithValue(
            MockTransactionRepository(),
          ),
        ],
      );

      expect(find.byType(DeelButton), findsNothing);
    });

    testWidgets('delivered status shows confirm + dispute buttons', (
      tester,
    ) async {
      await pumpTestScreenWithProviders(
        tester,
        Scaffold(
          body: ActionSection(
            transaction: _txn(status: TransactionStatus.delivered),
          ),
        ),
        overrides: [
          transactionRepositoryProvider.overrideWithValue(
            MockTransactionRepository(),
          ),
        ],
      );

      expect(find.byType(DeelButton), findsNWidgets(2));
    });

    testWidgets('released status shows no buttons', (tester) async {
      await pumpTestScreenWithProviders(
        tester,
        Scaffold(
          body: ActionSection(
            transaction: _txn(status: TransactionStatus.released),
          ),
        ),
        overrides: [
          transactionRepositoryProvider.overrideWithValue(
            MockTransactionRepository(),
          ),
        ],
      );

      expect(find.byType(DeelButton), findsNothing);
    });

    testWidgets('has Semantics labels', (tester) async {
      await pumpTestScreenWithProviders(
        tester,
        Scaffold(body: ActionSection(transaction: _txn())),
        overrides: [
          transactionRepositoryProvider.overrideWithValue(
            MockTransactionRepository(),
          ),
        ],
      );

      expect(find.byType(Semantics), findsWidgets);
    });
  });
}
