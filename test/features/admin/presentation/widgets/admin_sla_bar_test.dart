import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
  });
}
