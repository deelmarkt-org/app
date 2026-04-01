import 'package:flutter/foundation.dart';

import 'package:deelmarkt/features/auth/domain/repositories/auth_repository.dart';

/// In-memory mock for development when Supabase Auth (R-13) isn't ready.
///
/// Simulates registration flow with delays. Accepts any 6-digit OTP.
/// Toggle via provider override in dev builds.
class MockAuthRepository implements AuthRepository {
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
}
