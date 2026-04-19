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
  const tPhone = '+31612345678';
  const tToken = '123456';

  // Stub for AuthResponse (used by datasource return values)
  final tAuthResponse = sb.AuthResponse();

  // ---------------------------------------------------------------------------
  // Helper: creates an sb.AuthException with the given message and statusCode
  // ---------------------------------------------------------------------------
  sb.AuthException authException(String message, {String? statusCode}) =>
      sb.AuthException(message, statusCode: statusCode);

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
}
