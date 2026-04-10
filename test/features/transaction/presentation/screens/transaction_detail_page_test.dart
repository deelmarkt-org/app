import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/transaction/data/mock/mock_transaction_repository.dart';
import 'package:deelmarkt/features/transaction/presentation/screens/transaction_detail_page.dart';
import 'package:deelmarkt/features/transaction/presentation/screens/transaction_detail_screen.dart';
import 'package:deelmarkt/widgets/feedback/error_state.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('TransactionDetailPage', () {
    testWidgets('shows loading then data for known transaction', (
      tester,
    ) async {
      await pumpTestScreenWithProviders(
        tester,
        const TransactionDetailPage(transactionId: 'txn-001'),
        overrides: [
          transactionRepositoryProvider.overrideWithValue(
            MockTransactionRepository(),
          ),
        ],
      );

      expect(find.byType(TransactionDetailScreen), findsOneWidget);
    });

    testWidgets('shows error for unknown transaction', (tester) async {
      await pumpTestScreenWithProviders(
        tester,
        const TransactionDetailPage(transactionId: 'nonexistent'),
        overrides: [
          transactionRepositoryProvider.overrideWithValue(
            MockTransactionRepository(),
          ),
        ],
      );

      expect(find.byType(ErrorState), findsOneWidget);
    });
  });
}
