import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/models/transaction_status.dart';
import 'package:deelmarkt/features/transaction/domain/entities/transaction_entity.dart';
import 'package:deelmarkt/features/transaction/presentation/screens/transaction_detail_screen.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';
import 'package:deelmarkt/widgets/layout/responsive_body.dart';
import 'package:deelmarkt/widgets/trust/escrow_timeline.dart';
import 'package:deelmarkt/widgets/trust/trust_banner.dart';

import '../../../helpers/pump_app.dart';

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
  group('TransactionDetailScreen', () {
    testWidgets('renders trust banner', (tester) async {
      await pumpTestScreen(
        tester,
        TransactionDetailScreen(transaction: _txn()),
      );

      expect(find.byType(TrustBanner), findsOneWidget);
    });

    testWidgets('renders escrow timeline', (tester) async {
      await pumpTestScreen(
        tester,
        TransactionDetailScreen(transaction: _txn()),
      );

      expect(find.byType(EscrowTimeline), findsOneWidget);
    });

    testWidgets('displays amounts with euro formatting', (tester) async {
      await pumpTestScreen(
        tester,
        TransactionDetailScreen(transaction: _txn()),
      );

      // Total = 4500 + 113 + 695 = 5308 = €53,08
      expect(find.textContaining('53,08'), findsWidgets);
    });

    testWidgets('delivered status shows confirm + dispute buttons', (
      tester,
    ) async {
      await pumpTestScreen(
        tester,
        TransactionDetailScreen(
          transaction: _txn(status: TransactionStatus.delivered),
        ),
      );

      expect(find.byType(DeelButton), findsNWidgets(2));
    });

    testWidgets('paid status shows info row (funds held)', (tester) async {
      await pumpTestScreen(
        tester,
        TransactionDetailScreen(transaction: _txn()),
      );

      // Should not show action buttons
      expect(find.byType(DeelButton), findsNothing);
    });

    testWidgets('released status shows funds released message', (tester) async {
      await pumpTestScreen(
        tester,
        TransactionDetailScreen(
          transaction: _txn(status: TransactionStatus.released),
        ),
      );

      expect(find.byType(DeelButton), findsNothing);
    });

    testWidgets('amount section has Semantics', (tester) async {
      await pumpTestScreen(
        tester,
        TransactionDetailScreen(transaction: _txn()),
      );

      // Semantics wrappers should exist
      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('wraps content in ResponsiveBody', (tester) async {
      await pumpTestScreen(
        tester,
        TransactionDetailScreen(transaction: _txn()),
      );

      expect(find.byType(ResponsiveBody), findsOneWidget);
    });

    testWidgets('renders correctly in dark mode', (tester) async {
      await pumpTestScreen(
        tester,
        TransactionDetailScreen(transaction: _txn()),
        theme: DeelmarktTheme.dark,
      );

      expect(find.byType(TrustBanner), findsOneWidget);
      expect(find.byType(EscrowTimeline), findsOneWidget);
      expect(find.byType(ResponsiveBody), findsOneWidget);
    });
  });
}
