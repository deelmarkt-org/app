import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:deelmarkt/core/services/supabase_service.dart';
import 'package:deelmarkt/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:deelmarkt/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:deelmarkt/features/auth/domain/repositories/auth_repository.dart';
import 'package:deelmarkt/features/auth/domain/usecases/register_with_email_usecase.dart';
import 'package:deelmarkt/features/auth/domain/usecases/resend_email_otp_usecase.dart';
import 'package:deelmarkt/features/auth/domain/usecases/send_phone_otp_usecase.dart';
import 'package:deelmarkt/features/auth/domain/usecases/verify_email_otp_usecase.dart';
import 'package:deelmarkt/features/auth/domain/usecases/verify_phone_otp_usecase.dart';

part 'auth_providers.g.dart';

/// Provides the [AuthRepository] — overridable in tests.
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  final datasource = AuthRemoteDatasource(client);
  return AuthRepositoryImpl(datasource);
}

@riverpod
RegisterWithEmailUseCase registerWithEmailUseCase(Ref ref) {
  return RegisterWithEmailUseCase(ref.watch(authRepositoryProvider));
}

@riverpod
ResendEmailOtpUseCase resendEmailOtpUseCase(Ref ref) {
  return ResendEmailOtpUseCase(ref.watch(authRepositoryProvider));
}

@riverpod
VerifyEmailOtpUseCase verifyEmailOtpUseCase(Ref ref) {
  return VerifyEmailOtpUseCase(ref.watch(authRepositoryProvider));
}

@riverpod
SendPhoneOtpUseCase sendPhoneOtpUseCase(Ref ref) {
  return SendPhoneOtpUseCase(ref.watch(authRepositoryProvider));
}

@riverpod
VerifyPhoneOtpUseCase verifyPhoneOtpUseCase(Ref ref) {
  return VerifyPhoneOtpUseCase(ref.watch(authRepositoryProvider));
}
