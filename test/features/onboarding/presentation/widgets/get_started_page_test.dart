import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/onboarding/presentation/widgets/get_started_page.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('GetStartedPage', () {
    Widget buildPage({VoidCallback? onCreateAccount, VoidCallback? onLogin}) =>
        GetStartedPage(
          onCreateAccount: onCreateAccount ?? () {},
          onLogin: onLogin ?? () {},
        );

    testWidgets('renders title', (tester) async {
      await pumpTestWidget(tester, buildPage());
      expect(find.text('onboarding.ready_title'), findsOneWidget);
    });

    testWidgets('renders subtitle', (tester) async {
      await pumpTestWidget(tester, buildPage());
      expect(find.text('onboarding.ready_subtitle'), findsOneWidget);
    });

    testWidgets('renders 2 DeelButton widgets', (tester) async {
      await pumpTestWidget(tester, buildPage());
      expect(find.byType(DeelButton), findsNWidgets(2));
    });

    testWidgets('renders create account button text', (tester) async {
      await pumpTestWidget(tester, buildPage());
      expect(find.text('onboarding.create_account'), findsOneWidget);
    });

    testWidgets('renders login link text', (tester) async {
      await pumpTestWidget(tester, buildPage());
      expect(find.text('onboarding.have_account'), findsOneWidget);
    });

    testWidgets('has handshake illustration Semantics', (tester) async {
      await pumpTestWidget(tester, buildPage());
      expect(
        find.bySemanticsLabel('onboarding.handshake_illustration'),
        findsOneWidget,
      );
    });
  });
}
