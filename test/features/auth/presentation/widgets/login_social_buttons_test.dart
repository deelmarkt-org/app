import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/features/auth/domain/entities/auth_result.dart';
import 'package:deelmarkt/features/auth/domain/repositories/auth_repository.dart';
import 'package:deelmarkt/features/auth/presentation/viewmodels/auth_providers.dart';
import 'package:deelmarkt/features/auth/presentation/widgets/login_social_buttons.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

import '../../../../helpers/a11y_touch_target_utils.dart';
import '../../../../helpers/pump_app.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
  });

  Future<void> pump(WidgetTester tester, {ThemeData? theme}) =>
      pumpTestScreenWithProviders(
        tester,
        const Scaffold(body: LoginSocialButtons()),
        overrides: [authRepositoryProvider.overrideWithValue(mockRepo)],
        theme: theme,
      );

  // Google is rendered via DeelButton (outline). Apple is a custom filled-black
  // ElevatedButton per HIG.
  Finder googleButton() => find.byType(DeelButton);
  Finder appleButton() => find.byType(ElevatedButton);

  group('LoginSocialButtons', () {
    testWidgets('renders Google (DeelButton) + Apple (ElevatedButton)', (
      tester,
    ) async {
      await pump(tester);

      expect(googleButton(), findsOneWidget);
      expect(appleButton(), findsOneWidget);
    });

    testWidgets('both buttons enabled when idle', (tester) async {
      await pump(tester);

      final google = tester.widget<DeelButton>(googleButton());
      final apple = tester.widget<ElevatedButton>(appleButton());
      expect(google.onPressed, isNotNull);
      expect(apple.onPressed, isNotNull);
    });

    testWidgets('tapping Google calls loginWithOAuth(google)', (tester) async {
      when(
        () => mockRepo.loginWithOAuth(OAuthProvider.google),
      ).thenAnswer((_) async => const AuthFailureOAuthCancelled());

      await pump(tester);
      await tester.tap(googleButton());
      await tester.pump();

      verify(() => mockRepo.loginWithOAuth(OAuthProvider.google)).called(1);
    });

    testWidgets('tapping Apple calls loginWithOAuth(apple)', (tester) async {
      when(
        () => mockRepo.loginWithOAuth(OAuthProvider.apple),
      ).thenAnswer((_) async => const AuthFailureOAuthCancelled());

      await pump(tester);
      await tester.tap(appleButton());
      await tester.pump();

      verify(() => mockRepo.loginWithOAuth(OAuthProvider.apple)).called(1);
    });

    testWidgets('buttons disabled while any OAuth is loading', (tester) async {
      final completer = Completer<AuthResult>();
      when(
        () => mockRepo.loginWithOAuth(OAuthProvider.google),
      ).thenAnswer((_) => completer.future);

      await pump(tester);
      await tester.tap(googleButton());
      await tester.pump();

      final google = tester.widget<DeelButton>(googleButton());
      final apple = tester.widget<ElevatedButton>(appleButton());
      expect(google.onPressed, isNull);
      expect(apple.onPressed, isNull);

      completer.complete(const AuthFailureOAuthCancelled());
      await tester.pumpAndSettle();
    });

    testWidgets('OAuthCancelled is silent', (tester) async {
      when(
        () => mockRepo.loginWithOAuth(OAuthProvider.google),
      ).thenAnswer((_) async => const AuthFailureOAuthCancelled());

      await pump(tester);
      await tester.tap(googleButton());
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('OAuthUnavailable shows a SnackBar', (tester) async {
      when(
        () => mockRepo.loginWithOAuth(OAuthProvider.google),
      ).thenAnswer((_) async => const AuthFailureOAuthUnavailable());

      await pump(tester);
      await tester.tap(googleButton());
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('NetworkError shows a SnackBar', (tester) async {
      when(
        () => mockRepo.loginWithOAuth(OAuthProvider.google),
      ).thenAnswer((_) async => const AuthFailureNetworkError(message: 'err'));

      await pump(tester);
      await tester.tap(googleButton());
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  group('LoginSocialButtons — accessibility', () {
    testWidgets('both buttons meet WCAG 2.2 AA 44×44 touch target', (
      tester,
    ) async {
      await pump(tester);

      expectMeetsMinTouchTarget(tester, googleButton());
      expectMeetsMinTouchTarget(tester, appleButton());
    });

    testWidgets('Apple button meets 52px HIG height', (tester) async {
      await pump(tester);

      final size = tester.getSize(appleButton());
      expect(size.height, greaterThanOrEqualTo(52));
    });

    testWidgets('both buttons render a localisation-key label', (tester) async {
      await pump(tester);

      // easy_localization .tr() falls back to the key when no translation is
      // loaded in the test context, so we assert the key itself is rendered.
      expect(find.text('auth.continueWithGoogle'), findsWidgets);
      expect(find.text('auth.continueWithApple'), findsWidgets);
    });
  });

  group('LoginSocialButtons — Apple HIG dark mode', () {
    testWidgets('Apple button uses dark bg + white fg in light mode', (
      tester,
    ) async {
      await pump(tester, theme: DeelmarktTheme.light);

      final apple = tester.widget<ElevatedButton>(appleButton());
      final bg = apple.style!.backgroundColor!.resolve(<WidgetState>{});
      final fg = apple.style!.foregroundColor!.resolve(<WidgetState>{});
      expect(bg, DeelmarktColors.neutral900);
      expect(fg, DeelmarktColors.white);
    });

    testWidgets('Apple button uses white bg + dark fg in dark mode', (
      tester,
    ) async {
      await pump(tester, theme: DeelmarktTheme.dark);

      final apple = tester.widget<ElevatedButton>(appleButton());
      final bg = apple.style!.backgroundColor!.resolve(<WidgetState>{});
      final fg = apple.style!.foregroundColor!.resolve(<WidgetState>{});
      expect(bg, DeelmarktColors.white);
      expect(fg, DeelmarktColors.neutral900);
    });

    testWidgets('Apple loading spinner renders in dark mode', (tester) async {
      final completer = Completer<AuthResult>();
      when(
        () => mockRepo.loginWithOAuth(OAuthProvider.apple),
      ).thenAnswer((_) => completer.future);

      await pump(tester, theme: DeelmarktTheme.dark);
      await tester.tap(appleButton());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(const AuthFailureOAuthCancelled());
      await tester.pumpAndSettle();
    });
  });
}
