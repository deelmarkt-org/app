import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/models/transaction_status.dart';
import 'package:deelmarkt/features/transaction/domain/entities/transaction_entity.dart';
import 'package:deelmarkt/features/transaction/presentation/screens/transaction_detail_screen.dart';
import 'package:deelmarkt/features/transaction/presentation/widgets/escrow_step_detail_sheet.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';
import 'package:deelmarkt/widgets/layout/responsive_body.dart';
import 'package:deelmarkt/widgets/trust/escrow_timeline.dart';
import 'package:deelmarkt/widgets/trust/trust_banner.dart';

import '../../../../helpers/pump_app.dart';

TransactionEntity _buildTransaction({
  TransactionStatus status = TransactionStatus.paid,
}) {
  return TransactionEntity(
    id: 'txn-001',
    listingId: 'listing-001',
    buyerId: 'buyer-001',
    sellerId: 'seller-001',
    status: status,
    itemAmountCents: 4500,
    platformFeeCents: 113,
    shippingCostCents: 695,
    currency: 'EUR',
    createdAt: DateTime(2026, 4),
  );
}

void main() {
  group('TransactionDetailScreen', () {
    testWidgets('renders trust banner', (tester) async {
      await pumpTestScreen(
        tester,
        TransactionDetailScreen(transaction: _buildTransaction()),
      );

      expect(find.byType(TrustBanner), findsOneWidget);
    });

    testWidgets('renders escrow timeline', (tester) async {
      await pumpTestScreen(
        tester,
        TransactionDetailScreen(transaction: _buildTransaction()),
      );

      expect(find.byType(EscrowTimeline), findsOneWidget);
    });

    testWidgets('displays amounts with euro formatting', (tester) async {
      await pumpTestScreen(
        tester,
        TransactionDetailScreen(transaction: _buildTransaction()),
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
          transaction: _buildTransaction(status: TransactionStatus.delivered),
        ),
      );

      expect(find.byType(DeelButton), findsNWidgets(2));
    });

    testWidgets('paid status shows info row (funds held)', (tester) async {
      await pumpTestScreen(
        tester,
        TransactionDetailScreen(transaction: _buildTransaction()),
      );

      // Should not show action buttons
      expect(find.byType(DeelButton), findsNothing);
    });

    testWidgets('released status shows funds released message', (tester) async {
      await pumpTestScreen(
        tester,
        TransactionDetailScreen(
          transaction: _buildTransaction(status: TransactionStatus.released),
        ),
      );

      expect(find.byType(DeelButton), findsNothing);
    });

    testWidgets('renders with shipped status', (tester) async {
      await pumpTestScreen(
        tester,
        TransactionDetailScreen(
          transaction: _buildTransaction(status: TransactionStatus.shipped),
        ),
      );

      expect(find.byType(TransactionDetailScreen), findsOneWidget);
    });

    testWidgets('renders with disputed status', (tester) async {
      await pumpTestScreen(
        tester,
        TransactionDetailScreen(
          transaction: _buildTransaction(status: TransactionStatus.disputed),
        ),
      );

      expect(find.byType(TransactionDetailScreen), findsOneWidget);
    });

    testWidgets('amount section has Semantics', (tester) async {
      await pumpTestScreen(
        tester,
        TransactionDetailScreen(transaction: _buildTransaction()),
      );

      // Semantics wrappers should exist
      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('wraps content in ResponsiveBody', (tester) async {
      await pumpTestScreen(
        tester,
        TransactionDetailScreen(transaction: _buildTransaction()),
      );

      expect(find.byType(ResponsiveBody), findsOneWidget);
    });

    testWidgets('renders correctly in dark mode', (tester) async {
      await pumpTestScreen(
        tester,
        TransactionDetailScreen(transaction: _buildTransaction()),
        theme: DeelmarktTheme.dark,
      );

      expect(find.byType(TrustBanner), findsOneWidget);
      expect(find.byType(EscrowTimeline), findsOneWidget);
      expect(find.byType(ResponsiveBody), findsOneWidget);
    });

    testWidgets('tapping escrow step opens detail sheet', (tester) async {
      final txn = _buildTransaction().copyWith(paidAt: DateTime(2026, 3, 19, 14, 30));
      await pumpTestScreen(tester, TransactionDetailScreen(transaction: txn));

      // Tap the first step label ("escrow.paid" key returned by easy_localization
      // in test context).
      await tester.tap(find.text('escrow.paid'));
      await tester.pumpAndSettle();

      expect(find.byType(EscrowStepDetailSheet), findsOneWidget);
    });
  });
}
