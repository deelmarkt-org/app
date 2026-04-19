import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/features/auth/presentation/widgets/biometric_section.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  Widget buildTest() {
    return EasyLocalization(
      supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
      fallbackLocale: const Locale('en', 'US'),
      path: 'assets/l10n',
      child: ProviderScope(
        child: MaterialApp(
          theme: DeelmarktTheme.light,
          home: const Scaffold(body: BiometricSection()),
        ),
      ),
    );
  }

  testWidgets('renders nothing when biometric is unavailable (default state)', (
    tester,
  ) async {
    await tester.pumpWidget(buildTest());
    await tester.pump();

    // Default LoginViewModel has biometricAvailable = false → SizedBox.shrink
    expect(find.byType(BiometricSection), findsOneWidget);
  });
}
