import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:deelmarkt/core/exceptions/app_exception.dart';
import 'package:deelmarkt/features/auth/data/biometric_service.dart';
import 'package:deelmarkt/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:deelmarkt/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:deelmarkt/features/auth/domain/entities/auth_result.dart';

class MockAuthRemoteDatasource extends Mock implements AuthRemoteDatasource {}

class MockBiometricService extends Mock implements BiometricService {}

void main() {
  late MockAuthRemoteDatasource mockDatasource;
  late MockBiometricService mockBiometricService;
  late AuthRepositoryImpl repository;

  setUp(() {
    mockDatasource = MockAuthRemoteDatasource();
    mockBiometricService = MockBiometricService();
    repository = AuthRepositoryImpl(
      mockDatasource,
      biometricService: mockBiometricService,
    );
  });

  // ---------------------------------------------------------------------------
  // Shared test fixtures
  // ---------------------------------------------------------------------------
  const tEmail = 'test@example.com';
  const tPassword = 'SecureP@ss1'; // pragma: allowlist secret
  final tTermsAccepted = DateTime(2026);
  final tPrivacyAccepted = DateTime(2026);

  // Stub for AuthResponse (used by datasource return values)
  final tAuthResponse = sb.AuthResponse();

  // ---------------------------------------------------------------------------
  // Helper: creates an sb.AuthException with the given message and statusCode
  // ---------------------------------------------------------------------------
  sb.AuthException authException(String message, {String? statusCode}) =>
      sb.AuthException(message, statusCode: statusCode);

  group('loginWithEmail', () {
    void arrangeSignIn(sb.AuthResponse response) {
      when(
        () => mockDatasource.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => response);
    }

    void arrangeSignInThrows(Object error) {
      when(
        () => mockDatasource.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(error);
    }

    Future<AuthResult> act() =>
        repository.loginWithEmail(email: tEmail, password: tPassword);

    test('returns AuthSuccess with userId on success', () async {
      final response = sb.AuthResponse(
        user: sb.User(
          id: 'user-123',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
        ),
      );
      arrangeSignIn(response);

      final result = await act();

      expect(result, isA<AuthSuccess>());
      expect((result as AuthSuccess).userId, 'user-123');
    });

    test('returns AuthFailureUnknown when user is null', () async {
      arrangeSignIn(tAuthResponse);

      final result = await act();

      expect(result, isA<AuthFailureUnknown>());
    });

    test('returns AuthFailureRateLimited on status 429', () async {
      arrangeSignInThrows(
        authException('Too many requests', statusCode: '429'),
      );

      final result = await act();

      expect(result, isA<AuthFailureRateLimited>());
    });

    test('returns AuthFailureInvalidCredentials on status 400', () async {
      arrangeSignInThrows(
        authException('Invalid credentials', statusCode: '400'),
      );

      final result = await act();

      expect(result, isA<AuthFailureInvalidCredentials>());
    });

    test(
      'returns AuthFailureInvalidCredentials on "invalid login" message',
      () async {
        arrangeSignInThrows(authException('Invalid login credentials'));

        final result = await act();

        expect(result, isA<AuthFailureInvalidCredentials>());
      },
    );

    test(
      'returns AuthFailureInvalidCredentials on "invalid credential" message',
      () async {
        arrangeSignInThrows(authException('Invalid credential provided'));

        final result = await act();

        expect(result, isA<AuthFailureInvalidCredentials>());
      },
    );

    test('returns AuthFailureRateLimited on "rate" in message', () async {
      arrangeSignInThrows(authException('Rate limit exceeded'));

      final result = await act();

      expect(result, isA<AuthFailureRateLimited>());
    });

    test('returns AuthFailureUnknown for unrecognised AuthException', () async {
      arrangeSignInThrows(authException('Something weird', statusCode: '500'));

      final result = await act();

      expect(result, isA<AuthFailureUnknown>());
      expect((result as AuthFailureUnknown).message, 'auth_error_status_500');
    });

    test('returns AuthFailureNetworkError on socket error', () async {
      arrangeSignInThrows(Exception('SocketException: Connection refused'));

      final result = await act();

      expect(result, isA<AuthFailureNetworkError>());
    });

    test('returns AuthFailureNetworkError on timeout error', () async {
      arrangeSignInThrows(Exception('Request timeout'));

      final result = await act();

      expect(result, isA<AuthFailureNetworkError>());
    });

    test('returns AuthFailureUnknown on unknown generic error', () async {
      arrangeSignInThrows(Exception('Completely unexpected'));

      final result = await act();

      expect(result, isA<AuthFailureUnknown>());
      expect((result as AuthFailureUnknown).message, 'unknown_login_error');
    });
  });

  group('network error detection', () {
    // Exercise all four network keywords via registerWithEmail
    // (any method works — they all share _mapGenericError)

    void arrangeThrows(Object error) {
      when(
        () => mockDatasource.signUpWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
          metadata: any(named: 'metadata'),
        ),
      ).thenThrow(error);
    }

    Future<void> act() => repository.registerWithEmail(
      email: tEmail,
      password: tPassword,
      termsAcceptedAt: tTermsAccepted,
      privacyAcceptedAt: tPrivacyAccepted,
    );

    test('detects "socket" keyword as NetworkException', () {
      arrangeThrows(Exception('SocketException: OS Error'));
      expect(act, throwsA(isA<NetworkException>()));
    });

    test('detects "connection" keyword as NetworkException', () {
      arrangeThrows(Exception('Connection reset by peer'));
      expect(act, throwsA(isA<NetworkException>()));
    });

    test('detects "network" keyword as NetworkException', () {
      arrangeThrows(Exception('Network is unreachable'));
      expect(act, throwsA(isA<NetworkException>()));
    });

    test('detects "timeout" keyword as NetworkException', () {
      arrangeThrows(Exception('Request timeout'));
      expect(act, throwsA(isA<NetworkException>()));
    });

    test('non-network generic error maps to AuthException(error.generic)', () {
      arrangeThrows(Exception('Null check operator used on a null value'));
      expect(
        act,
        throwsA(
          isA<AuthException>().having(
            (e) => e.messageKey,
            'messageKey',
            'error.generic',
          ),
        ),
      );
    });
  });

  group('loginWithOAuth', () {
    setUp(() {
      // Short stream so any accidental web-path subscription closes cleanly.
      when(
        () => mockDatasource.authStateChanges,
      ).thenAnswer((_) => const Stream<sb.AuthState>.empty());
    });

    sb.AuthResponse responseWithUser(String id) {
      // AuthResponse.user is derived from its session; simplest to stub a
      // Session with a fake User via sb.User construction.
      return sb.AuthResponse(
        user: sb.User(
          id: id,
          appMetadata: const {},
          userMetadata: const {},
          aud: 'authenticated',
          createdAt: DateTime(2026).toIso8601String(),
        ),
      );
    }

    test('Google native success returns AuthSuccess with user id', () async {
      when(
        () => mockDatasource.signInWithGoogle(),
      ).thenAnswer((_) async => responseWithUser('uid-g'));

      final result = await repository.loginWithOAuth(OAuthProvider.google);

      expect(result, isA<AuthSuccess>());
      expect((result as AuthSuccess).userId, 'uid-g');
    });

    test('Apple native success returns AuthSuccess', () async {
      when(
        () => mockDatasource.signInWithApple(),
      ).thenAnswer((_) async => responseWithUser('uid-a'));

      final result = await repository.loginWithOAuth(OAuthProvider.apple);

      expect(result, isA<AuthSuccess>());
    });

    test('null datasource response returns OAuthCancelled', () async {
      when(
        () => mockDatasource.signInWithGoogle(),
      ).thenAnswer((_) async => null);

      final result = await repository.loginWithOAuth(OAuthProvider.google);

      expect(result, isA<AuthFailureOAuthCancelled>());
    });

    test('AuthException provider_disabled → OAuthUnavailable', () async {
      when(() => mockDatasource.signInWithApple()).thenThrow(
        const sb.AuthException('Provider is disabled', statusCode: '422'),
      );

      final result = await repository.loginWithOAuth(OAuthProvider.apple);

      expect(result, isA<AuthFailureOAuthUnavailable>());
    });

    test('AuthException 429 → RateLimited via mapOAuthAuthError', () async {
      when(
        () => mockDatasource.signInWithGoogle(),
      ).thenThrow(const sb.AuthException('rate limited', statusCode: '429'));

      final result = await repository.loginWithOAuth(OAuthProvider.google);

      expect(result, isA<AuthFailureRateLimited>());
    });

    test('generic network error → NetworkError', () async {
      when(
        () => mockDatasource.signInWithGoogle(),
      ).thenThrow(Exception('SocketException: connection refused'));

      final result = await repository.loginWithOAuth(OAuthProvider.google);

      expect(result, isA<AuthFailureNetworkError>());
    });

    test('AuthResponse without user id returns AuthFailureUnknown', () async {
      when(
        () => mockDatasource.signInWithGoogle(),
      ).thenAnswer((_) async => sb.AuthResponse()); // no session, no user

      final result = await repository.loginWithOAuth(OAuthProvider.google);

      expect(result, isA<AuthFailureUnknown>());
    });
  });
}
