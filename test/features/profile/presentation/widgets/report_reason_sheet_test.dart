import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/profile/domain/entities/report_reason.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/report_reason_sheet.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('ReportReasonSheet', () {
    testWidgets('renders title', (tester) async {
      await pumpTestWidget(tester, ReportReasonSheet(onSubmit: (_) async {}));

      expect(find.text('report.title'), findsOneWidget);
    });

    testWidgets('renders a ListTile for every ReportReason', (tester) async {
      await pumpTestWidget(tester, ReportReasonSheet(onSubmit: (_) async {}));

      for (final reason in ReportReason.values) {
        expect(
          find.text(reasonL10nKey(reason)),
          findsOneWidget,
          reason: '${reason.name} ListTile not found',
        );
      }
    });

    testWidgets('tapping a reason calls onSubmit with that reason', (
      tester,
    ) async {
      ReportReason? submitted;

      await pumpTestWidget(
        tester,
        ReportReasonSheet(
          onSubmit: (r) async {
            submitted = r;
          },
        ),
      );

      await tester.tap(find.text(reasonL10nKey(ReportReason.scam)));
      await tester.pumpAndSettle();

      expect(submitted, ReportReason.scam);
    });

    testWidgets('tapping another reason calls onSubmit with that reason', (
      tester,
    ) async {
      ReportReason? submitted;

      await pumpTestWidget(
        tester,
        ReportReasonSheet(
          onSubmit: (r) async {
            submitted = r;
          },
        ),
      );

      await tester.tap(find.text(reasonL10nKey(ReportReason.spam)));
      await tester.pumpAndSettle();

      expect(submitted, ReportReason.spam);
    });

    testWidgets('all ReportReason values render exactly once', (tester) async {
      await pumpTestWidget(tester, ReportReasonSheet(onSubmit: (_) async {}));

      expect(find.byType(ListTile), findsNWidgets(ReportReason.values.length));
    });
  });
}
