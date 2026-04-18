import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:deelmarkt/core/exceptions/app_exception.dart';
import 'package:deelmarkt/features/auth/data/biometric_service.dart';
import 'package:deelmarkt/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:deelmarkt/features/auth/data/repositories/auth_repository_impl.dart';

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
  const tToken = '123456';

  // Stub for AuthResponse (used by datasource return values)
  final tAuthResponse = sb.AuthResponse();

  // ---------------------------------------------------------------------------
  // Helper: creates an sb.AuthException with the given message and statusCode
  // ---------------------------------------------------------------------------
  sb.AuthException authException(String message, {String? statusCode}) =>
      sb.AuthException(message, statusCode: statusCode);

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
}
