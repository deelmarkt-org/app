/// Canonical test entry-point for [EscrowTimeline].
///
/// Comprehensive tests are intentionally split into focused files:
/// - `escrow_timeline_happy_test.dart` — happy-path step rendering + interaction
/// - `escrow_timeline_offpath_test.dart` — disputed/cancelled/expired variants
///
/// This file satisfies the CLAUDE.md §6 quality gate (one test file per source
/// file) and provides a quick smoke test that the widget mounts without error.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/models/transaction_status.dart';
import 'package:deelmarkt/widgets/trust/escrow_timeline.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('EscrowTimeline mounts without error', (tester) async {
    await pumpTestWidget(
      tester,
      const SizedBox(
        width: 400,
        child: EscrowTimeline(currentStatus: TransactionStatus.paid),
      ),
    );
    expect(find.byType(EscrowTimeline), findsOneWidget);
  });
}
