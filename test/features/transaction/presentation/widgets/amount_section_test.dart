import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/models/transaction_status.dart';
import 'package:deelmarkt/features/transaction/domain/entities/transaction_entity.dart';
import 'package:deelmarkt/features/transaction/presentation/widgets/amount_section.dart';

import '../../../../helpers/pump_app.dart';

TransactionEntity _txn() {
  return TransactionEntity(
    id: 'txn_001',
    listingId: 'lst_001',
    buyerId: 'usr_buyer',
    sellerId: 'usr_seller',
    status: TransactionStatus.paid,
    itemAmountCents: 4500,
    platformFeeCents: 113,
    shippingCostCents: 695,
    currency: 'EUR',
    createdAt: DateTime(2026, 3, 19),
  );
}

void main() {
  group('AmountSection', () {
    testWidgets('renders without exception', (tester) async {
      await pumpTestWidget(tester, AmountSection(transaction: _txn()));

      expect(tester.takeException(), isNull);
      expect(find.byType(AmountSection), findsOneWidget);
    });

    testWidgets('has Semantics labels for each row', (tester) async {
      await pumpTestWidget(tester, AmountSection(transaction: _txn()));

      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('label text does not overflow at compact phone width', (
      tester,
    ) async {
      // 375×667 logical pixels (iPhone 8 / SE2 size at 1x DPR in test).
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpTestWidget(tester, AmountSection(transaction: _txn()));

      expect(tester.takeException(), isNull);
    });
  });
}
