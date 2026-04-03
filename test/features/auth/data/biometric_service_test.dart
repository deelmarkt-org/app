import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mocktail/mocktail.dart';

import 'package:deelmarkt/features/auth/data/biometric_service.dart';
import 'package:deelmarkt/features/auth/domain/entities/auth_result.dart';

class MockLocalAuthentication extends Mock implements LocalAuthentication {}

void main() {
  late MockLocalAuthentication mockLocalAuth;
  late BiometricService service;

  setUpAll(() {
    registerFallbackValue(
      const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
    );
  });

  setUp(() {
    mockLocalAuth = MockLocalAuthentication();
    service = BiometricService(localAuth: mockLocalAuth);
  });

  // ---------------------------------------------------------------------------
  // isAvailable
  // ---------------------------------------------------------------------------
  group('BiometricService — isAvailable', () {
    test(
      'returns true when biometrics can check and device is supported',
      () async {
        when(
          () => mockLocalAuth.canCheckBiometrics,
        ).thenAnswer((_) async => true);
        when(
          () => mockLocalAuth.isDeviceSupported(),
        ).thenAnswer((_) async => true);

        expect(await service.isAvailable, true);
      },
    );

    test('returns false when cannot check biometrics', () async {
      when(
        () => mockLocalAuth.canCheckBiometrics,
      ).thenAnswer((_) async => false);
      when(
        () => mockLocalAuth.isDeviceSupported(),
      ).thenAnswer((_) async => true);

      expect(await service.isAvailable, false);
    });

    test('returns false when device not supported', () async {
      when(
        () => mockLocalAuth.canCheckBiometrics,
      ).thenAnswer((_) async => true);
      when(
        () => mockLocalAuth.isDeviceSupported(),
      ).thenAnswer((_) async => false);

      expect(await service.isAvailable, false);
    });

    test('returns false when both unavailable', () async {
      when(
        () => mockLocalAuth.canCheckBiometrics,
      ).thenAnswer((_) async => false);
      when(
        () => mockLocalAuth.isDeviceSupported(),
      ).thenAnswer((_) async => false);

      expect(await service.isAvailable, false);
    });

    test('returns false on PlatformException', () async {
      when(
        () => mockLocalAuth.canCheckBiometrics,
      ).thenThrow(PlatformException(code: 'ERROR'));

      expect(await service.isAvailable, false);
    });
  });

  // ---------------------------------------------------------------------------
  // authenticate
  // ---------------------------------------------------------------------------
  group('BiometricService — authenticate', () {
    test('returns true on successful authentication', () async {
      when(
        () => mockLocalAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => true);

      expect(await service.authenticate(localizedReason: 'Test'), true);
    });

    test('returns false on failed authentication', () async {
      when(
        () => mockLocalAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => false);

      expect(await service.authenticate(localizedReason: 'Test'), false);
    });

    test('returns false on PlatformException', () async {
      when(
        () => mockLocalAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
        ),
      ).thenThrow(PlatformException(code: 'ERROR'));

      expect(await service.authenticate(localizedReason: 'Test'), false);
    });

    test('passes stickyAuth and biometricOnly options', () async {
      when(
        () => mockLocalAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => true);

      await service.authenticate(localizedReason: 'Verify');

      verify(
        () => mockLocalAuth.authenticate(
          localizedReason: 'Verify',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        ),
      ).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // availableMethod
  // ---------------------------------------------------------------------------
  group('BiometricService — availableMethod', () {
    test('returns face when face type is available', () async {
      when(
        () => mockLocalAuth.getAvailableBiometrics(),
      ).thenAnswer((_) async => [BiometricType.face]);

      expect(await service.availableMethod, BiometricMethod.face);
    });

    test('returns fingerprint when fingerprint type is available', () async {
      when(
        () => mockLocalAuth.getAvailableBiometrics(),
      ).thenAnswer((_) async => [BiometricType.fingerprint]);

      expect(await service.availableMethod, BiometricMethod.fingerprint);
    });

    test('returns fingerprint when only strong type is available', () async {
      when(
        () => mockLocalAuth.getAvailableBiometrics(),
      ).thenAnswer((_) async => [BiometricType.strong]);

      expect(await service.availableMethod, BiometricMethod.fingerprint);
    });

    test('prefers face over fingerprint when both available', () async {
      when(() => mockLocalAuth.getAvailableBiometrics()).thenAnswer(
        (_) async => [BiometricType.fingerprint, BiometricType.face],
      );

      expect(await service.availableMethod, BiometricMethod.face);
    });

    test('prefers face over strong when both available', () async {
      when(
        () => mockLocalAuth.getAvailableBiometrics(),
      ).thenAnswer((_) async => [BiometricType.strong, BiometricType.face]);

      expect(await service.availableMethod, BiometricMethod.face);
    });

    test('returns null when no biometrics available', () async {
      when(
        () => mockLocalAuth.getAvailableBiometrics(),
      ).thenAnswer((_) async => []);

      expect(await service.availableMethod, isNull);
    });

    test('returns null when only weak type available', () async {
      when(
        () => mockLocalAuth.getAvailableBiometrics(),
      ).thenAnswer((_) async => [BiometricType.weak]);

      expect(await service.availableMethod, isNull);
    });

    test('returns null on PlatformException', () async {
      when(
        () => mockLocalAuth.getAvailableBiometrics(),
      ).thenThrow(PlatformException(code: 'ERROR'));

      expect(await service.availableMethod, isNull);
    });
  });
}
