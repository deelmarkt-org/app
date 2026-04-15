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
  const tPhone = '+31612345678';
  const tToken = '123456';
  final tTermsAccepted = DateTime(2026);
  final tPrivacyAccepted = DateTime(2026);

  // Stub for AuthResponse (used by datasource return values)
  final tAuthResponse = sb.AuthResponse();

  // ---------------------------------------------------------------------------
  // Helper: creates an sb.AuthException with the given message and statusCode
  // ---------------------------------------------------------------------------
  sb.AuthException authException(String message, {String? statusCode}) =>
      sb.AuthException(message, statusCode: statusCode);

  // ---------------------------------------------------------------------------
  // registerWithEmail
  // ---------------------------------------------------------------------------
  group('registerWithEmail', () {
    void arrangeSuccess() {
      when(
        () => mockDatasource.signUpWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
          metadata: any(named: 'metadata'),
        ),
      ).thenAnswer((_) async => tAuthResponse);
    }

    test('delegates to datasource with correct parameters', () async {
      arrangeSuccess();

      await repository.registerWithEmail(
        email: tEmail,
        password: tPassword,
        termsAcceptedAt: tTermsAccepted,
        privacyAcceptedAt: tPrivacyAccepted,
      );

      // Timestamps are now generated server-side in the repository,
      // so we verify metadata is passed (any map) rather than exact values.
      verify(
        () => mockDatasource.signUpWithEmail(
          email: tEmail,
          password: tPassword,
          metadata: any(named: 'metadata'),
        ),
      ).called(1);
    });

    test('completes without error on success', () async {
      arrangeSuccess();

      await expectLater(
        repository.registerWithEmail(
          email: tEmail,
          password: tPassword,
          termsAcceptedAt: tTermsAccepted,
          privacyAcceptedAt: tPrivacyAccepted,
        ),
        completes,
      );
    });

    test('throws AuthException(error.email_taken) '
        'when datasource throws "already registered"', () async {
      when(
        () => mockDatasource.signUpWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
          metadata: any(named: 'metadata'),
        ),
      ).thenThrow(authException('User already registered'));

      expect(
        () => repository.registerWithEmail(
          email: tEmail,
          password: tPassword,
          termsAcceptedAt: tTermsAccepted,
          privacyAcceptedAt: tPrivacyAccepted,
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.messageKey,
            'messageKey',
            'error.email_taken',
          ),
        ),
      );
    });

    test('throws AuthException(error.email_taken) '
        'when message contains "already been registered"', () async {
      when(
        () => mockDatasource.signUpWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
          metadata: any(named: 'metadata'),
        ),
      ).thenThrow(authException('Email has already been registered'));

      expect(
        () => repository.registerWithEmail(
          email: tEmail,
          password: tPassword,
          termsAcceptedAt: tTermsAccepted,
          privacyAcceptedAt: tPrivacyAccepted,
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.messageKey,
            'messageKey',
            'error.email_taken',
          ),
        ),
      );
    });

    test('throws NetworkException on socket error', () async {
      when(
        () => mockDatasource.signUpWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
          metadata: any(named: 'metadata'),
        ),
      ).thenThrow(Exception('SocketException: Connection refused'));

      expect(
        () => repository.registerWithEmail(
          email: tEmail,
          password: tPassword,
          termsAcceptedAt: tTermsAccepted,
          privacyAcceptedAt: tPrivacyAccepted,
        ),
        throwsA(isA<NetworkException>()),
      );
    });

    test(
      'throws AuthException(error.generic) on unknown generic error',
      () async {
        when(
          () => mockDatasource.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
            metadata: any(named: 'metadata'),
          ),
        ).thenThrow(Exception('Something completely unexpected'));

        expect(
          () => repository.registerWithEmail(
            email: tEmail,
            password: tPassword,
            termsAcceptedAt: tTermsAccepted,
            privacyAcceptedAt: tPrivacyAccepted,
          ),
          throwsA(
            isA<AuthException>().having(
              (e) => e.messageKey,
              'messageKey',
              'error.generic',
            ),
          ),
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // verifyEmailOtp
  // ---------------------------------------------------------------------------
  group('verifyEmailOtp', () {
    void arrangeSuccess() {
      when(
        () => mockDatasource.verifyEmailOtp(
          email: any(named: 'email'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async => tAuthResponse);
    }

    test('delegates to datasource with correct parameters', () async {
      arrangeSuccess();

      await repository.verifyEmailOtp(email: tEmail, token: tToken);

      verify(
        () => mockDatasource.verifyEmailOtp(email: tEmail, token: tToken),
      ).called(1);
    });

    test('completes without error on success', () async {
      arrangeSuccess();

      await expectLater(
        repository.verifyEmailOtp(email: tEmail, token: tToken),
        completes,
      );
    });

    test('throws AuthException(error.otp_invalid) '
        'when message contains "invalid" and "otp"', () async {
      when(
        () => mockDatasource.verifyEmailOtp(
          email: any(named: 'email'),
          token: any(named: 'token'),
        ),
      ).thenThrow(authException('Invalid OTP provided'));

      expect(
        () => repository.verifyEmailOtp(email: tEmail, token: tToken),
        throwsA(
          isA<AuthException>().having(
            (e) => e.messageKey,
            'messageKey',
            'error.otp_invalid',
          ),
        ),
      );
    });

    test('throws AuthException(error.otp_invalid) '
        'when message contains "invalid" and "token"', () async {
      when(
        () => mockDatasource.verifyEmailOtp(
          email: any(named: 'email'),
          token: any(named: 'token'),
        ),
      ).thenThrow(authException('Invalid token supplied'));

      expect(
        () => repository.verifyEmailOtp(email: tEmail, token: tToken),
        throwsA(
          isA<AuthException>().having(
            (e) => e.messageKey,
            'messageKey',
            'error.otp_invalid',
          ),
        ),
      );
    });

    test(
      'throws AuthException(error.otp_expired) when message contains "expired"',
      () async {
        when(
          () => mockDatasource.verifyEmailOtp(
            email: any(named: 'email'),
            token: any(named: 'token'),
          ),
        ).thenThrow(authException('Token has expired'));

        expect(
          () => repository.verifyEmailOtp(email: tEmail, token: tToken),
          throwsA(
            isA<AuthException>().having(
              (e) => e.messageKey,
              'messageKey',
              'error.otp_expired',
            ),
          ),
        );
      },
    );

    test(
      'throws AuthException(error.rate_limited) when statusCode is 429',
      () async {
        when(
          () => mockDatasource.verifyEmailOtp(
            email: any(named: 'email'),
            token: any(named: 'token'),
          ),
        ).thenThrow(authException('Too many requests', statusCode: '429'));

        expect(
          () => repository.verifyEmailOtp(email: tEmail, token: tToken),
          throwsA(
            isA<AuthException>().having(
              (e) => e.messageKey,
              'messageKey',
              'error.rate_limited',
            ),
          ),
        );
      },
    );

    test('throws AuthException(error.rate_limited) '
        'when message contains "rate"', () async {
      when(
        () => mockDatasource.verifyEmailOtp(
          email: any(named: 'email'),
          token: any(named: 'token'),
        ),
      ).thenThrow(authException('Rate limit exceeded'));

      expect(
        () => repository.verifyEmailOtp(email: tEmail, token: tToken),
        throwsA(
          isA<AuthException>().having(
            (e) => e.messageKey,
            'messageKey',
            'error.rate_limited',
          ),
        ),
      );
    });

    test('throws AuthException(error.generic) with debugMessage '
        'for unrecognised AuthException', () async {
      when(
        () => mockDatasource.verifyEmailOtp(
          email: any(named: 'email'),
          token: any(named: 'token'),
        ),
      ).thenThrow(authException('Unknown auth error', statusCode: '500'));

      expect(
        () => repository.verifyEmailOtp(email: tEmail, token: tToken),
        throwsA(
          isA<AuthException>()
              .having((e) => e.messageKey, 'messageKey', 'error.generic')
              .having(
                (e) => e.debugMessage,
                'debugMessage',
                'auth_error_status_500',
              ),
        ),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // resendEmailOtp
  // ---------------------------------------------------------------------------
  group('resendEmailOtp', () {
    void arrangeSuccess() {
      when(
        () => mockDatasource.resendEmailOtp(email: any(named: 'email')),
      ).thenAnswer((_) async {});
    }

    test('delegates to datasource with correct email', () async {
      arrangeSuccess();

      await repository.resendEmailOtp(email: tEmail);

      verify(() => mockDatasource.resendEmailOtp(email: tEmail)).called(1);
    });

    test('completes without error on success', () async {
      arrangeSuccess();

      await expectLater(repository.resendEmailOtp(email: tEmail), completes);
    });

    test('throws AuthException(error.rate_limited) on status 429', () async {
      when(
        () => mockDatasource.resendEmailOtp(email: any(named: 'email')),
      ).thenThrow(authException('For security purposes', statusCode: '429'));

      expect(
        () => repository.resendEmailOtp(email: tEmail),
        throwsA(
          isA<AuthException>().having(
            (e) => e.messageKey,
            'messageKey',
            'error.rate_limited',
          ),
        ),
      );
    });

    test(
      'throws AuthException(error.generic) for unknown AuthException',
      () async {
        when(
          () => mockDatasource.resendEmailOtp(email: any(named: 'email')),
        ).thenThrow(authException('Some auth error'));

        expect(
          () => repository.resendEmailOtp(email: tEmail),
          throwsA(
            isA<AuthException>().having(
              (e) => e.messageKey,
              'messageKey',
              'error.generic',
            ),
          ),
        );
      },
    );

    test('throws NetworkException on connection error', () async {
      when(
        () => mockDatasource.resendEmailOtp(email: any(named: 'email')),
      ).thenThrow(Exception('Connection refused'));

      expect(
        () => repository.resendEmailOtp(email: tEmail),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // sendPhoneOtp
  // ---------------------------------------------------------------------------
  group('sendPhoneOtp', () {
    void arrangeSuccess() {
      when(
        () => mockDatasource.sendPhoneOtp(phone: any(named: 'phone')),
      ).thenAnswer((_) async {});
    }

    test('delegates to datasource with correct phone', () async {
      arrangeSuccess();

      await repository.sendPhoneOtp(phone: tPhone);

      verify(() => mockDatasource.sendPhoneOtp(phone: tPhone)).called(1);
    });

    test('completes without error on success', () async {
      arrangeSuccess();

      await expectLater(repository.sendPhoneOtp(phone: tPhone), completes);
    });

    test(
      'throws AuthException(error.rate_limited) when message contains "rate"',
      () async {
        when(
          () => mockDatasource.sendPhoneOtp(phone: any(named: 'phone')),
        ).thenThrow(authException('Rate limit reached'));

        expect(
          () => repository.sendPhoneOtp(phone: tPhone),
          throwsA(
            isA<AuthException>().having(
              (e) => e.messageKey,
              'messageKey',
              'error.rate_limited',
            ),
          ),
        );
      },
    );

    test(
      'throws AuthException(error.generic) for unrecognised AuthException',
      () async {
        when(
          () => mockDatasource.sendPhoneOtp(phone: any(named: 'phone')),
        ).thenThrow(authException('Unexpected error', statusCode: '503'));

        expect(
          () => repository.sendPhoneOtp(phone: tPhone),
          throwsA(
            isA<AuthException>()
                .having((e) => e.messageKey, 'messageKey', 'error.generic')
                .having(
                  (e) => e.debugMessage,
                  'debugMessage',
                  'auth_error_status_503',
                ),
          ),
        );
      },
    );

    test('throws NetworkException on timeout error', () async {
      when(
        () => mockDatasource.sendPhoneOtp(phone: any(named: 'phone')),
      ).thenThrow(Exception('timeout after 30 seconds'));

      expect(
        () => repository.sendPhoneOtp(phone: tPhone),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // verifyPhoneOtp
  // ---------------------------------------------------------------------------
  group('verifyPhoneOtp', () {
    void arrangeSuccess() {
      when(
        () => mockDatasource.verifyPhoneOtp(
          phone: any(named: 'phone'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async => tAuthResponse);
    }

    test('delegates to datasource with correct parameters', () async {
      arrangeSuccess();

      await repository.verifyPhoneOtp(phone: tPhone, token: tToken);

      verify(
        () => mockDatasource.verifyPhoneOtp(phone: tPhone, token: tToken),
      ).called(1);
    });

    test('completes without error on success', () async {
      arrangeSuccess();

      await expectLater(
        repository.verifyPhoneOtp(phone: tPhone, token: tToken),
        completes,
      );
    });

    test('throws AuthException(error.otp_invalid) '
        'when message contains "invalid" and "otp"', () async {
      when(
        () => mockDatasource.verifyPhoneOtp(
          phone: any(named: 'phone'),
          token: any(named: 'token'),
        ),
      ).thenThrow(authException('OTP is invalid'));

      expect(
        () => repository.verifyPhoneOtp(phone: tPhone, token: tToken),
        throwsA(
          isA<AuthException>().having(
            (e) => e.messageKey,
            'messageKey',
            'error.otp_invalid',
          ),
        ),
      );
    });

    test(
      'throws AuthException(error.otp_expired) when message contains "expired"',
      () async {
        when(
          () => mockDatasource.verifyPhoneOtp(
            phone: any(named: 'phone'),
            token: any(named: 'token'),
          ),
        ).thenThrow(authException('OTP has expired'));

        expect(
          () => repository.verifyPhoneOtp(phone: tPhone, token: tToken),
          throwsA(
            isA<AuthException>().having(
              (e) => e.messageKey,
              'messageKey',
              'error.otp_expired',
            ),
          ),
        );
      },
    );

    test('throws AuthException(error.rate_limited) on status 429', () async {
      when(
        () => mockDatasource.verifyPhoneOtp(
          phone: any(named: 'phone'),
          token: any(named: 'token'),
        ),
      ).thenThrow(authException('Slow down', statusCode: '429'));

      expect(
        () => repository.verifyPhoneOtp(phone: tPhone, token: tToken),
        throwsA(
          isA<AuthException>().having(
            (e) => e.messageKey,
            'messageKey',
            'error.rate_limited',
          ),
        ),
      );
    });

    test(
      'throws AuthException(error.generic) for unrecognised AuthException',
      () async {
        when(
          () => mockDatasource.verifyPhoneOtp(
            phone: any(named: 'phone'),
            token: any(named: 'token'),
          ),
        ).thenThrow(authException('Weird auth error'));

        expect(
          () => repository.verifyPhoneOtp(phone: tPhone, token: tToken),
          throwsA(
            isA<AuthException>().having(
              (e) => e.messageKey,
              'messageKey',
              'error.generic',
            ),
          ),
        );
      },
    );

    test('throws NetworkException on network error', () async {
      when(
        () => mockDatasource.verifyPhoneOtp(
          phone: any(named: 'phone'),
          token: any(named: 'token'),
        ),
      ).thenThrow(Exception('Network is unreachable'));

      expect(
        () => repository.verifyPhoneOtp(phone: tPhone, token: tToken),
        throwsA(isA<NetworkException>()),
      );
    });

    test(
      'throws AuthException(error.generic) on unknown generic error',
      () async {
        when(
          () => mockDatasource.verifyPhoneOtp(
            phone: any(named: 'phone'),
            token: any(named: 'token'),
          ),
        ).thenThrow(Exception('Something completely unexpected'));

        expect(
          () => repository.verifyPhoneOtp(phone: tPhone, token: tToken),
          throwsA(
            isA<AuthException>().having(
              (e) => e.messageKey,
              'messageKey',
              'error.generic',
            ),
          ),
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // loginWithEmail (P-16)
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // loginWithBiometric (P-16)
  // ---------------------------------------------------------------------------
  group('loginWithBiometric', () {
    const tReason = 'Verify identity';

    test(
      'returns AuthFailureBiometricUnavailable when not available',
      () async {
        when(
          () => mockBiometricService.isAvailable,
        ).thenAnswer((_) async => false);

        final result = await repository.loginWithBiometric(
          localizedReason: tReason,
        );

        expect(result, isA<AuthFailureBiometricUnavailable>());
      },
    );

    test('returns AuthFailureBiometricUnavailable when no session', () async {
      when(
        () => mockBiometricService.isAvailable,
      ).thenAnswer((_) async => true);
      when(() => mockDatasource.currentSession).thenReturn(null);

      final result = await repository.loginWithBiometric(
        localizedReason: tReason,
      );

      expect(result, isA<AuthFailureBiometricUnavailable>());
    });

    test('returns AuthFailureBiometricFailed when auth fails', () async {
      when(
        () => mockBiometricService.isAvailable,
      ).thenAnswer((_) async => true);
      when(() => mockDatasource.currentSession).thenReturn(
        sb.Session(
          accessToken: 'token',
          tokenType: 'bearer',
          user: sb.User(
            id: '1',
            appMetadata: {},
            userMetadata: {},
            aud: 'authenticated',
            createdAt: DateTime.now().toIso8601String(),
          ),
        ),
      );
      when(
        () => mockBiometricService.authenticate(
          localizedReason: any(named: 'localizedReason'),
        ),
      ).thenAnswer((_) async => false);

      final result = await repository.loginWithBiometric(
        localizedReason: tReason,
      );

      expect(result, isA<AuthFailureBiometricFailed>());
    });

    test('returns AuthSuccess on successful biometric + refresh', () async {
      final tUser = sb.User(
        id: 'bio-user',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      );
      when(
        () => mockBiometricService.isAvailable,
      ).thenAnswer((_) async => true);
      when(() => mockDatasource.currentSession).thenReturn(
        sb.Session(accessToken: 'token', tokenType: 'bearer', user: tUser),
      );
      when(
        () => mockBiometricService.authenticate(
          localizedReason: any(named: 'localizedReason'),
        ),
      ).thenAnswer((_) async => true);
      when(
        () => mockDatasource.refreshSession(),
      ).thenAnswer((_) async => sb.AuthResponse(user: tUser));

      final result = await repository.loginWithBiometric(
        localizedReason: tReason,
      );

      expect(result, isA<AuthSuccess>());
      expect((result as AuthSuccess).userId, 'bio-user');
    });

    test('returns AuthFailureSessionExpired when refresh fails', () async {
      final tUser = sb.User(
        id: '1',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      );
      when(
        () => mockBiometricService.isAvailable,
      ).thenAnswer((_) async => true);
      when(() => mockDatasource.currentSession).thenReturn(
        sb.Session(accessToken: 'token', tokenType: 'bearer', user: tUser),
      );
      when(
        () => mockBiometricService.authenticate(
          localizedReason: any(named: 'localizedReason'),
        ),
      ).thenAnswer((_) async => true);
      when(
        () => mockDatasource.refreshSession(),
      ).thenThrow(authException('Session expired'));

      final result = await repository.loginWithBiometric(
        localizedReason: tReason,
      );

      expect(result, isA<AuthFailureSessionExpired>());
    });

    test(
      'returns AuthFailureSessionExpired when user is null after refresh',
      () async {
        final tUser = sb.User(
          id: '1',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
        );
        when(
          () => mockBiometricService.isAvailable,
        ).thenAnswer((_) async => true);
        when(() => mockDatasource.currentSession).thenReturn(
          sb.Session(accessToken: 'token', tokenType: 'bearer', user: tUser),
        );
        when(
          () => mockBiometricService.authenticate(
            localizedReason: any(named: 'localizedReason'),
          ),
        ).thenAnswer((_) async => true);
        when(
          () => mockDatasource.refreshSession(),
        ).thenAnswer((_) async => sb.AuthResponse());

        final result = await repository.loginWithBiometric(
          localizedReason: tReason,
        );

        expect(result, isA<AuthFailureSessionExpired>());
      },
    );
  });

  // ---------------------------------------------------------------------------
  // isBiometricAvailable
  // ---------------------------------------------------------------------------
  group('isBiometricAvailable', () {
    test('returns false when biometric hardware unavailable', () async {
      when(
        () => mockBiometricService.isAvailable,
      ).thenAnswer((_) async => false);

      expect(await repository.isBiometricAvailable, false);
    });

    test('returns false when no session exists', () async {
      when(
        () => mockBiometricService.isAvailable,
      ).thenAnswer((_) async => true);
      when(() => mockDatasource.currentSession).thenReturn(null);

      expect(await repository.isBiometricAvailable, false);
    });

    test('returns true when biometric available and session exists', () async {
      when(
        () => mockBiometricService.isAvailable,
      ).thenAnswer((_) async => true);
      when(() => mockDatasource.currentSession).thenReturn(
        sb.Session(
          accessToken: 'token',
          tokenType: 'bearer',
          user: sb.User(
            id: '1',
            appMetadata: {},
            userMetadata: {},
            aud: 'authenticated',
            createdAt: DateTime.now().toIso8601String(),
          ),
        ),
      );

      expect(await repository.isBiometricAvailable, true);
    });
  });

  // ---------------------------------------------------------------------------
  // availableBiometricMethod
  // ---------------------------------------------------------------------------
  group('availableBiometricMethod', () {
    test('delegates to biometricService.availableMethod', () async {
      when(
        () => mockBiometricService.availableMethod,
      ).thenAnswer((_) async => BiometricMethod.face);

      expect(await repository.availableBiometricMethod, BiometricMethod.face);
    });

    test('returns null when no method available', () async {
      when(
        () => mockBiometricService.availableMethod,
      ).thenAnswer((_) async => null);

      expect(await repository.availableBiometricMethod, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // _mapGenericError — network detection coverage
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // loginWithOAuth (P-44) — native flow
  // ---------------------------------------------------------------------------
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
