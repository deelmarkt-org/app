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
}
