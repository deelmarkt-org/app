/// Screenshot driver — Transaction detail screen.
///
/// Hero screen #7: escrow trust signals.
/// Spec: docs/screens/04-payments/03-transaction-detail.md
/// Reference: PLAN-p43-aso.md §WS-B
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/domain/entities/transaction_entity.dart';
import 'package:deelmarkt/core/models/transaction_status.dart';
import 'package:deelmarkt/features/transaction/presentation/screens/transaction_detail_screen.dart';

import '../_support/device_frames.dart';
import '../_support/screenshot_driver.dart';
import '../_support/seed_data.dart';

final _mockTransaction = TransactionEntity(
  id: kScreenshotTransactionId,
  listingId: 'listing-001',
  buyerId: 'user-002',
  sellerId: kScreenshotCurrentUserId,
  status: TransactionStatus.paid,
  itemAmountCents: 89500,
  platformFeeCents: 1790,
  shippingCostCents: 695,
  currency: 'EUR',
  createdAt: DateTime(2026, 4, 14, 10),
  paidAt: DateTime(2026, 4, 14, 10, 30),
);

void main() {
  setUpAll(initScreenshotEnvironment);

  for (final device in kScreenshotDevices) {
    for (final locale in kScreenshotLocales) {
      for (final theme in ScreenshotTheme.values) {
        testWidgets('transaction_detail ${device.id} $locale ${theme.name}', (
          tester,
        ) async {
          await captureScreenshot(
            tester: tester,
            screen: TransactionDetailScreen(transaction: _mockTransaction),
            locale: locale,
            theme: theme,
            device: device,
            goldenName: 'transaction_detail',
          );
        });
      }
    }
  }
}
