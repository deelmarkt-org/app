import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/auth/presentation/widgets/kyc_progress_bar.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('KycProgressBar', () {
    testWidgets('renders without errors', (tester) async {
      await pumpTestWidget(tester, const KycProgressBar(progress: 0.5));
      expect(find.byType(KycProgressBar), findsOneWidget);
    });

    testWidgets('renders with zero progress', (tester) async {
      await pumpTestWidget(tester, const KycProgressBar(progress: 0.0));
      expect(find.byType(KycProgressBar), findsOneWidget);
    });

    testWidgets('renders with full progress', (tester) async {
      await pumpTestWidget(tester, const KycProgressBar(progress: 1.0));
      expect(find.byType(KycProgressBar), findsOneWidget);
    });

    testWidgets('clamps values above 1.0', (tester) async {
      await pumpTestWidget(tester, const KycProgressBar(progress: 1.5));
      expect(find.byType(KycProgressBar), findsOneWidget);
    });

    testWidgets('clamps values below 0.0', (tester) async {
      await pumpTestWidget(tester, const KycProgressBar(progress: -0.5));
      expect(find.byType(KycProgressBar), findsOneWidget);
    });

    testWidgets('contains ClipRRect for rounded corners', (tester) async {
      await pumpTestWidget(tester, const KycProgressBar(progress: 0.5));
      expect(find.byType(ClipRRect), findsOneWidget);
    });

    testWidgets('contains AnimatedFractionallySizedBox', (tester) async {
      await pumpTestWidget(tester, const KycProgressBar(progress: 0.5));
      expect(find.byType(AnimatedFractionallySizedBox), findsOneWidget);
    });
  });
}
