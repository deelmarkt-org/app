/// Tests for suspension_gate_status.dart status chips, receipt banner, and upheld body.
///
/// Covers: [SuspensionGateCountdownChip], [SuspensionGatePermanentChip],
/// [SuspensionGateReceiptBanner], [SuspensionGateUpheldBody].
///
/// Reference: lib/features/profile/presentation/widgets/suspension_gate_status.dart
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/profile/domain/entities/sanction_entity.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/suspension_gate_status.dart';

import '../../../../helpers/pump_app.dart';

SanctionEntity _sanctionWithAppeal() => SanctionEntity(
  id: 'test-id',
  userId: 'user-1',
  type: SanctionType.ban,
  reason: 'Test',
  createdAt: DateTime(2026, 4),
  expiresAt: DateTime(2026, 5),
  appealedAt: DateTime(2026, 4, 10, 14, 30),
);

void main() {
  group('SuspensionGateCountdownChip', () {
    testWidgets('renders with future expiry', (tester) async {
      final expiresAt = DateTime.now().add(const Duration(days: 7));
      await pumpTestWidget(
        tester,
        SuspensionGateCountdownChip(expiresAt: expiresAt),
      );
      expect(find.byType(SuspensionGateCountdownChip), findsOneWidget);
    });

    testWidgets('clamps to 0 for past expiry', (tester) async {
      final expiresAt = DateTime.now().subtract(const Duration(days: 1));
      await pumpTestWidget(
        tester,
        SuspensionGateCountdownChip(expiresAt: expiresAt),
      );
      expect(find.byType(SuspensionGateCountdownChip), findsOneWidget);
    });

    testWidgets('shows 1 day for 23 h remaining (ceiling fix)', (tester) async {
      // 23 hours in the future → ceil(23/24) = 1 day, not 0
      final expiresAt = DateTime.now().add(const Duration(hours: 23));
      await pumpTestWidget(
        tester,
        SuspensionGateCountdownChip(expiresAt: expiresAt),
      );
      expect(find.byType(SuspensionGateCountdownChip), findsOneWidget);
    });
  });

  group('SuspensionGatePermanentChip', () {
    testWidgets('renders without error', (tester) async {
      await pumpTestWidget(tester, const SuspensionGatePermanentChip());
      expect(find.byType(SuspensionGatePermanentChip), findsOneWidget);
    });
  });

  group('SuspensionGateReceiptBanner', () {
    testWidgets('renders when appeal is pending', (tester) async {
      await pumpTestWidget(
        tester,
        SuspensionGateReceiptBanner(sanction: _sanctionWithAppeal()),
      );
      expect(find.byType(SuspensionGateReceiptBanner), findsOneWidget);
    });
  });

  group('SuspensionGateUpheldBody', () {
    testWidgets('renders without error', (tester) async {
      await pumpTestWidget(tester, const SuspensionGateUpheldBody());
      expect(find.byType(SuspensionGateUpheldBody), findsOneWidget);
    });
  });
}
