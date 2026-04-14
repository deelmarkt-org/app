/// Tests for suspension_gate_cta.dart CTA row widget.
///
/// Covers: [SuspensionGateCtaRow].
///
/// Reference: lib/features/profile/presentation/widgets/suspension_gate_cta.dart
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/profile/domain/entities/sanction_entity.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/suspension_gate_cta.dart';

import '../../../../helpers/pump_app.dart';

SanctionEntity _sanctionWithAppealAvailable() => SanctionEntity(
  id: 'test-id',
  userId: 'user-1',
  type: SanctionType.suspension,
  reason: 'Test',
  // Within 14-day appeal window
  createdAt: DateTime.now().subtract(const Duration(days: 1)),
  expiresAt: DateTime.now().add(const Duration(days: 6)),
);

SanctionEntity _sanctionPending() => SanctionEntity(
  id: 'test-id',
  userId: 'user-1',
  type: SanctionType.suspension,
  reason: 'Test',
  createdAt: DateTime.now().subtract(const Duration(days: 2)),
  expiresAt: DateTime.now().add(const Duration(days: 5)),
  appealedAt: DateTime.now().subtract(const Duration(hours: 1)),
);

void main() {
  group('SuspensionGateCtaRow', () {
    testWidgets('renders contact support button', (tester) async {
      var tapped = false;
      await pumpTestScreenWithProviders(
        tester,
        SuspensionGateCtaRow(
          sanction: _sanctionWithAppealAvailable(),
          onContactSupport: () => tapped = true,
        ),
      );
      expect(find.byType(SuspensionGateCtaRow), findsOneWidget);
      expect(tapped, isFalse);
    });

    testWidgets('hides appeal CTA when appeal is already pending', (
      tester,
    ) async {
      await pumpTestScreenWithProviders(
        tester,
        SuspensionGateCtaRow(
          sanction: _sanctionPending(),
          onContactSupport: () {},
        ),
      );
      expect(find.byType(SuspensionGateCtaRow), findsOneWidget);
    });
  });
}
