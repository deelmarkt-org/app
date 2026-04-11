import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/features/admin/presentation/widgets/admin_sla_bar.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('AdminSlaBar', () {
    testWidgets('renders percentage label', (tester) async {
      await pumpTestWidget(
        tester,
        const AdminSlaBar(progress: 0.66, completed: 33, total: 50),
      );

      expect(find.text('66%'), findsOneWidget);
    });

    testWidgets('renders SLA title key text', (tester) async {
      await pumpTestWidget(
        tester,
        const AdminSlaBar(progress: 0.80, completed: 40, total: 50),
      );

      expect(find.text('admin.sla.title'), findsOneWidget);
    });

    testWidgets('contains a LinearProgressIndicator', (tester) async {
      await pumpTestWidget(
        tester,
        const AdminSlaBar(progress: 0.50, completed: 25, total: 50),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('progress >= 0.8 uses success color', (tester) async {
      await pumpTestWidget(
        tester,
        const AdminSlaBar(progress: 0.8, completed: 40, total: 50),
      );

      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      final color =
          (indicator.valueColor as AlwaysStoppedAnimation<Color?>).value;
      expect(color, equals(DeelmarktColors.success));
    });

    testWidgets('progress between 0.5 and 0.8 uses primary color', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        const AdminSlaBar(progress: 0.65, completed: 65, total: 100),
      );

      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      final color =
          (indicator.valueColor as AlwaysStoppedAnimation<Color?>).value;
      expect(color, equals(DeelmarktColors.primary));
    });

    testWidgets('progress below 0.5 uses error color', (tester) async {
      await pumpTestWidget(
        tester,
        const AdminSlaBar(progress: 0.3, completed: 3, total: 10),
      );

      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      final color =
          (indicator.valueColor as AlwaysStoppedAnimation<Color?>).value;
      expect(color, equals(DeelmarktColors.error));
    });

    testWidgets('renders status text with completed/total', (tester) async {
      await pumpTestWidget(
        tester,
        const AdminSlaBar(progress: 0.6, completed: 6, total: 10),
      );

      // l10n keys returned as-is in test environment
      expect(find.textContaining('admin.sla.status'), findsOneWidget);
    });
  });
}
