import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:deelmarkt/core/exceptions/app_exception.dart';
import 'package:deelmarkt/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:deelmarkt/features/auth/data/repositories/auth_repository_impl.dart';

class MockAuthRemoteDatasource extends Mock implements AuthRemoteDatasource {}

void main() {
  late MockAuthRemoteDatasource mockDatasource;
  late AuthRepositoryImpl repository;

  setUp(() {
    mockDatasource = MockAuthRemoteDatasource();
    repository = AuthRepositoryImpl(mockDatasource);
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
}
