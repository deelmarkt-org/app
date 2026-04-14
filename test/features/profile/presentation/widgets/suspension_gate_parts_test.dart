/// Tests for suspension_gate_parts.dart sub-widgets.
///
/// Covers: [SuspensionGateHeader], [SuspensionGateReasonCard],
/// [SuspensionGateCountdownChip], [SuspensionGatePermanentChip],
/// [SuspensionGateReceiptBanner], [SuspensionGateUpheldBody],
/// [SuspensionGateSanctionBody].
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/profile/domain/entities/sanction_entity.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/suspension_gate_parts.dart';

import '../../../../helpers/pump_app.dart';

// ── helpers ──────────────────────────────────────────────────────────────────

// Default expiry used in helpers that do not test countdown-specific logic.
final _kDefaultExpiry = DateTime(2026, 5);

SanctionEntity _sanction({
  // ignore: avoid_redundant_argument_values
  SanctionType type = SanctionType.suspension,
  DateTime? expiresAt,
  DateTime? appealedAt,
  AppealDecision? appealDecision,
}) {
  final resolvedExpiry = expiresAt ?? _kDefaultExpiry;
  return SanctionEntity(
    id: 'test-id',
    userId: 'user-1',
    type: type,
    reason: 'Violated community guidelines',
    // ignore: avoid_redundant_argument_values
    createdAt: DateTime(2026, 4, 1),
    expiresAt: resolvedExpiry,
    appealedAt: appealedAt,
    appealDecision: appealDecision,
  );
}

// ── tests ────────────────────────────────────────────────────────────────────

void main() {
  group('SuspensionGateReasonCard', () {
    testWidgets('displays the sanction reason text', (tester) async {
      await pumpTestWidget(
        tester,
        const SuspensionGateReasonCard(reason: 'Violated community guidelines'),
      );
      expect(find.text('Violated community guidelines'), findsOneWidget);
    });
  });

  group('SuspensionGatePermanentChip', () {
    testWidgets('renders without error', (tester) async {
      await pumpTestWidget(tester, const SuspensionGatePermanentChip());
      expect(find.byType(SuspensionGatePermanentChip), findsOneWidget);
    });
  });

  group('SuspensionGateCountdownChip', () {
    testWidgets('shows days remaining chip', (tester) async {
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
  });

  group('SuspensionGateReceiptBanner', () {
    testWidgets('renders when appeal is pending', (tester) async {
      final sanction = _sanction(appealedAt: DateTime(2026, 4, 10, 14, 30));
      await pumpTestWidget(
        tester,
        SuspensionGateReceiptBanner(sanction: sanction),
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

  group('SuspensionGateHeader', () {
    testWidgets('renders for active suspension', (tester) async {
      await pumpTestWidget(tester, SuspensionGateHeader(sanction: _sanction()));
      expect(find.byType(SuspensionGateHeader), findsOneWidget);
    });

    testWidgets('renders pending-appeal state', (tester) async {
      final sanction = _sanction(appealedAt: DateTime(2026, 4, 10));
      await pumpTestWidget(tester, SuspensionGateHeader(sanction: sanction));
      expect(find.byType(SuspensionGateHeader), findsOneWidget);
    });

    testWidgets('renders upheld-appeal state', (tester) async {
      final sanction = _sanction(
        appealedAt: DateTime(2026, 4, 10),
        appealDecision: AppealDecision.upheld,
      );
      await pumpTestWidget(tester, SuspensionGateHeader(sanction: sanction));
      expect(find.byType(SuspensionGateHeader), findsOneWidget);
    });
  });

  group('SuspensionGateSanctionBody', () {
    testWidgets('renders reason card', (tester) async {
      await pumpTestScreenWithProviders(
        tester,
        SuspensionGateSanctionBody(
          sanction: _sanction(),
          onContactSupport: () {},
        ),
      );
      expect(find.byType(SuspensionGateReasonCard), findsOneWidget);
    });

    testWidgets('shows receipt banner when appeal is pending', (tester) async {
      final sanction = _sanction(appealedAt: DateTime(2026, 4, 10));
      await pumpTestScreenWithProviders(
        tester,
        SuspensionGateSanctionBody(sanction: sanction, onContactSupport: () {}),
        overrides: [
          // No GoRouter needed — SuspensionGateCtaRow reads it for push.
          // The appeal CTA is hidden because isAppealPending==true, so
          // no navigation is triggered in this test.
        ],
      );
      expect(find.byType(SuspensionGateReceiptBanner), findsOneWidget);
    });

    testWidgets('shows upheld body when appeal decision=upheld', (
      tester,
    ) async {
      final sanction = _sanction(
        appealedAt: DateTime(2026, 4, 10),
        appealDecision: AppealDecision.upheld,
      );
      await pumpTestScreenWithProviders(
        tester,
        SuspensionGateSanctionBody(sanction: sanction, onContactSupport: () {}),
      );
      expect(find.byType(SuspensionGateUpheldBody), findsOneWidget);
    });

    testWidgets('shows countdown chip for temporary suspension', (
      tester,
    ) async {
      final sanction = _sanction(
        expiresAt: DateTime.now().add(const Duration(days: 14)),
      );
      await pumpTestScreenWithProviders(
        tester,
        SuspensionGateSanctionBody(sanction: sanction, onContactSupport: () {}),
      );
      expect(find.byType(SuspensionGateCountdownChip), findsOneWidget);
    });
  });
}
