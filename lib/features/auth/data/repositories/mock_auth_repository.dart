import 'package:flutter/foundation.dart';

import 'package:deelmarkt/features/auth/domain/entities/auth_result.dart';
import 'package:deelmarkt/features/auth/domain/repositories/auth_repository.dart';

/// In-memory mock for development when Supabase Auth (R-13) isn't ready.
///
/// Simulates registration flow with delays. Accepts any 6-digit OTP.
/// Toggle via provider override in dev builds.
class MockAuthRepository implements AuthRepository {
  static const String _mockUserId = 'mock-user-id';

  MockAuthRepository() {
    if (kReleaseMode) {
      throw StateError('MockAuthRepository cannot be used in release builds');
    }
  }

  @override
  Future<void> registerWithEmail({
    required String email,
    required String password,
    required DateTime termsAcceptedAt,
    required DateTime privacyAcceptedAt,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> resendEmailOtp({required String email}) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> sendPhoneOtp({required String phone}) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> verifyPhoneOtp({
    required String phone,
    required String token,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  // ── Login (P-16) ──

  @override
  Future<AuthResult> loginWithEmail({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    // Simulate invalid credentials for test convenience.
    final isInvalid = password == 'wrong'; // pragma: allowlist secret
    if (isInvalid) return const AuthFailureInvalidCredentials();
    return const AuthSuccess(userId: _mockUserId);
  }

  @override
  Future<AuthResult> loginWithBiometric({
    required String localizedReason,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return const AuthSuccess(userId: _mockUserId);
  }

  @override
  Future<bool> get isBiometricAvailable async => false;

  @override
  Future<BiometricMethod?> get availableBiometricMethod async => null;

  @override
  Future<AuthResult> loginWithOAuth(OAuthProvider provider) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return const AuthSuccess(userId: _mockUserId);
  }

  @override
  Future<String> initiateIdinVerification() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return 'https://www.idin.nl/mock-verify?session=test-123';
  }
}
