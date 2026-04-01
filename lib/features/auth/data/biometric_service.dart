import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:deelmarkt/features/auth/domain/entities/auth_result.dart';

part 'biometric_service.g.dart';

/// Wraps [LocalAuthentication] for testability and domain-level mapping.
///
/// The `localizedReason` passed to [authenticate] is displayed by the OS
/// in the biometric prompt — must come from l10n, never hardcoded English.
class BiometricService {
  BiometricService({LocalAuthentication? localAuth})
    : _localAuth = localAuth ?? LocalAuthentication();

  final LocalAuthentication _localAuth;

  /// Whether biometric hardware is available and at least one biometric
  /// is enrolled on the device.
  Future<bool> get isAvailable async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck && isSupported;
    } on PlatformException {
      return false;
    }
  }

  /// Trigger the OS biometric prompt. Returns `true` on success.
  Future<bool> authenticate({required String localizedReason}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  /// Which biometric method is available (face or fingerprint), or null.
  ///
  /// Maps `local_auth.BiometricType` → domain `BiometricMethod` to keep
  /// the domain layer free of third-party imports.
  Future<BiometricMethod?> get availableMethod async {
    try {
      final types = await _localAuth.getAvailableBiometrics();
      // Check specific types first — `strong` is a security tier (Class 3)
      // on Android that can include Face ID (e.g. Pixel 4), so only use it
      // as a generic fallback mapped to fingerprint.
      if (types.contains(BiometricType.face)) return BiometricMethod.face;
      if (types.contains(BiometricType.fingerprint)) {
        return BiometricMethod.fingerprint;
      }
      if (types.contains(BiometricType.strong)) {
        // `strong` may be face or fingerprint — we can't determine hardware
        // type from this tier alone. Default to fingerprint as the safer UX.
        return BiometricMethod.fingerprint;
      }
      return null;
    } on PlatformException {
      return null;
    }
  }
}

@Riverpod(keepAlive: true)
BiometricService biometricService(BiometricServiceRef ref) {
  return BiometricService();
}
