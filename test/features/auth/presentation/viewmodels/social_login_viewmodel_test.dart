import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:deelmarkt/features/auth/domain/entities/auth_result.dart';
import 'package:deelmarkt/features/auth/domain/repositories/auth_repository.dart';
import 'package:deelmarkt/features/auth/presentation/viewmodels/auth_providers.dart';
import 'package:deelmarkt/features/auth/presentation/viewmodels/social_login_viewmodel.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(mockRepo)],
    );
    addTearDown(container.dispose);
  });

  group('SocialLoginNotifier', () {
    test('initial state has no loading provider and no result', () {
      final state = container.read(socialLoginNotifierProvider);
      expect(state.loadingProvider, isNull);
      expect(state.result, isNull);
      expect(state.isLoading, isFalse);
    });

    test('signIn(google) sets loadingProvider=google during call', () async {
      when(() => mockRepo.loginWithOAuth(OAuthProvider.google)).thenAnswer((
        _,
      ) async {
        // Verify loading state mid-flight
        final s = container.read(socialLoginNotifierProvider);
        expect(s.loadingProvider, OAuthProvider.google);
        expect(s.isLoading, isTrue);
        return const AuthSuccess(userId: 'uid-123');
      });

      await container
          .read(socialLoginNotifierProvider.notifier)
          .signIn(OAuthProvider.google);
    });

    test('signIn returns AuthSuccess when repository succeeds', () async {
      when(
        () => mockRepo.loginWithOAuth(OAuthProvider.google),
      ).thenAnswer((_) async => const AuthSuccess(userId: 'uid-123'));

      final result = await container
          .read(socialLoginNotifierProvider.notifier)
          .signIn(OAuthProvider.google);

      expect(result, isA<AuthSuccess>());
      expect((result as AuthSuccess).userId, 'uid-123');
    });

    test('signIn clears loading state after completion', () async {
      when(
        () => mockRepo.loginWithOAuth(OAuthProvider.apple),
      ).thenAnswer((_) async => const AuthSuccess(userId: 'uid-456'));

      await container
          .read(socialLoginNotifierProvider.notifier)
          .signIn(OAuthProvider.apple);

      final state = container.read(socialLoginNotifierProvider);
      expect(state.loadingProvider, isNull);
      expect(state.isLoading, isFalse);
    });

    test(
      'signIn returns AuthFailureOAuthCancelled when user dismisses',
      () async {
        when(
          () => mockRepo.loginWithOAuth(OAuthProvider.google),
        ).thenAnswer((_) async => const AuthFailureOAuthCancelled());

        final result = await container
            .read(socialLoginNotifierProvider.notifier)
            .signIn(OAuthProvider.google);

        expect(result, isA<AuthFailureOAuthCancelled>());
        expect(container.read(socialLoginNotifierProvider).isLoading, isFalse);
      },
    );

    test(
      'signIn returns AuthFailureOAuthUnavailable when provider not configured',
      () async {
        when(
          () => mockRepo.loginWithOAuth(OAuthProvider.apple),
        ).thenAnswer((_) async => const AuthFailureOAuthUnavailable());

        final result = await container
            .read(socialLoginNotifierProvider.notifier)
            .signIn(OAuthProvider.apple);

        expect(result, isA<AuthFailureOAuthUnavailable>());
      },
    );

    test('signIn returns AuthFailureNetworkError on network failure', () async {
      when(
        () => mockRepo.loginWithOAuth(OAuthProvider.google),
      ).thenAnswer((_) async => const AuthFailureNetworkError(message: 'err'));

      final result = await container
          .read(socialLoginNotifierProvider.notifier)
          .signIn(OAuthProvider.google);

      expect(result, isA<AuthFailureNetworkError>());
    });

    test(
      'apple and google providers have independent loading indicators',
      () async {
        // Start google sign-in (don't await)
        when(
          () => mockRepo.loginWithOAuth(OAuthProvider.google),
        ).thenAnswer((_) async => const AuthSuccess(userId: 'g'));

        unawaited(
          container
              .read(socialLoginNotifierProvider.notifier)
              .signIn(OAuthProvider.google),
        );

        // While google is loading, loadingProvider should be google (not apple)
        final state = container.read(socialLoginNotifierProvider);
        expect(state.loadingProvider, OAuthProvider.google);
        expect(state.loadingProvider, isNot(OAuthProvider.apple));
      },
    );
  });
}
