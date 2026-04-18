import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

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
  // Helper: creates an sb.AuthException with the given message and statusCode
  // ---------------------------------------------------------------------------
  sb.AuthException authException(String message, {String? statusCode}) =>
      sb.AuthException(message, statusCode: statusCode);

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
}
