import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/features/home/presentation/widgets/escrow_badge.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  group('EscrowBadge', () {
    testWidgets('renders shield icon and text', (tester) async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
          fallbackLocale: const Locale('en', 'US'),
          path: 'assets/l10n',
          child: MaterialApp(
            theme: DeelmarktTheme.light,
            home: const Scaffold(body: EscrowBadge()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Icon), findsOneWidget);
      expect(find.byType(Text), findsOneWidget);
    });
  });
}
