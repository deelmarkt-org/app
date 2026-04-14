import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:deelmarkt/features/auth/domain/entities/auth_result.dart';
import 'package:deelmarkt/features/auth/domain/repositories/auth_repository.dart';
import 'package:deelmarkt/features/auth/presentation/viewmodels/auth_providers.dart';
import 'package:deelmarkt/features/auth/presentation/widgets/login_social_buttons.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

import '../../../../helpers/pump_app.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
  });

  Future<void> pump(WidgetTester tester) => pumpTestScreenWithProviders(
    tester,
    const Scaffold(body: LoginSocialButtons()),
    overrides: [authRepositoryProvider.overrideWithValue(mockRepo)],
  );

  group('LoginSocialButtons', () {
    testWidgets('renders two buttons in idle state', (tester) async {
      await pump(tester);

      expect(find.byType(DeelButton), findsNWidgets(2));
    });

    testWidgets('both buttons are enabled when not loading', (tester) async {
      await pump(tester);

      final buttons =
          tester.widgetList<DeelButton>(find.byType(DeelButton)).toList();
      expect(buttons[0].onPressed, isNotNull);
      expect(buttons[1].onPressed, isNotNull);
    });

    testWidgets('tapping Google button calls loginWithOAuth(google)', (
      tester,
    ) async {
      when(
        () => mockRepo.loginWithOAuth(OAuthProvider.google),
      ).thenAnswer((_) async => const AuthFailureOAuthCancelled());

      await pump(tester);
      await tester.tap(find.byType(DeelButton).first);
      await tester.pump();

      verify(() => mockRepo.loginWithOAuth(OAuthProvider.google)).called(1);
    });

    testWidgets('tapping Apple button calls loginWithOAuth(apple)', (
      tester,
    ) async {
      when(
        () => mockRepo.loginWithOAuth(OAuthProvider.apple),
      ).thenAnswer((_) async => const AuthFailureOAuthCancelled());

      await pump(tester);
      await tester.tap(find.byType(DeelButton).last);
      await tester.pump();

      verify(() => mockRepo.loginWithOAuth(OAuthProvider.apple)).called(1);
    });

    testWidgets('buttons are disabled while any OAuth is loading', (
      tester,
    ) async {
      final completer = Completer<AuthResult>();
      when(
        () => mockRepo.loginWithOAuth(OAuthProvider.google),
      ).thenAnswer((_) => completer.future);

      await pump(tester);
      await tester.tap(find.byType(DeelButton).first);
      await tester.pump(); // trigger state update

      final buttons =
          tester.widgetList<DeelButton>(find.byType(DeelButton)).toList();
      expect(buttons[0].onPressed, isNull);
      expect(buttons[1].onPressed, isNull);

      // Complete to avoid pending timer warning
      completer.complete(const AuthFailureOAuthCancelled());
      await tester.pumpAndSettle();
    });

    testWidgets('OAuthCancelled result is silent — no SnackBar', (
      tester,
    ) async {
      when(
        () => mockRepo.loginWithOAuth(OAuthProvider.google),
      ).thenAnswer((_) async => const AuthFailureOAuthCancelled());

      await pump(tester);
      await tester.tap(find.byType(DeelButton).first);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('OAuthUnavailable shows a SnackBar', (tester) async {
      when(
        () => mockRepo.loginWithOAuth(OAuthProvider.google),
      ).thenAnswer((_) async => const AuthFailureOAuthUnavailable());

      await pump(tester);
      await tester.tap(find.byType(DeelButton).first);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('NetworkError shows a SnackBar', (tester) async {
      when(
        () => mockRepo.loginWithOAuth(OAuthProvider.google),
      ).thenAnswer((_) async => const AuthFailureNetworkError(message: 'err'));

      await pump(tester);
      await tester.tap(find.byType(DeelButton).first);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
