import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:deelmarkt/features/auth/domain/usecases/check_kyc_required_usecase.dart';
import 'package:deelmarkt/features/auth/domain/usecases/initiate_idin_verification_usecase.dart';
import 'package:deelmarkt/features/auth/presentation/viewmodels/auth_providers.dart';
import 'package:deelmarkt/features/profile/domain/entities/user_entity.dart';

part 'kyc_prompt_viewmodel.g.dart';

/// State for the KYC prompt flow.
class KycPromptState {
  const KycPromptState({
    this.promptType = KycPromptType.none,
    this.isLoading = false,
    this.isSuccess = false,
    this.redirectUrl,
    this.error,
  });

  final KycPromptType promptType;
  final bool isLoading;
  final bool isSuccess;
  final String? redirectUrl;
  final String? error;

  KycPromptState copyWith({
    KycPromptType? promptType,
    bool? isLoading,
    bool? isSuccess,
    String? redirectUrl,
    String? error,
  }) {
    return KycPromptState(
      promptType: promptType ?? this.promptType,
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      redirectUrl: redirectUrl,
      error: error,
    );
  }
}

/// Provider for [CheckKycRequiredUseCase].
@riverpod
CheckKycRequiredUseCase checkKycRequired(Ref ref) {
  return const CheckKycRequiredUseCase();
}

/// Provider for [InitiateIdinVerificationUseCase].
@riverpod
InitiateIdinVerificationUseCase initiateIdinVerification(Ref ref) {
  return InitiateIdinVerificationUseCase(ref.watch(authRepositoryProvider));
}

/// ViewModel for KYC prompt — manages prompt type determination and iDIN flow.
@riverpod
class KycPromptNotifier extends _$KycPromptNotifier {
  @override
  KycPromptState build() {
    return const KycPromptState();
  }

  /// Check what KYC prompt (if any) to show.
  void checkRequired({
    required KycLevel kycLevel,
    int? transactionAmountCents,
  }) {
    final checkKyc = ref.read(checkKycRequiredProvider);
    final promptType = checkKyc(
      kycLevel: kycLevel,
      transactionAmountCents: transactionAmountCents,
    );
    state = KycPromptState(promptType: promptType);
  }

  /// Initiate iDIN verification flow.
  Future<void> initiateIdin() async {
    state = state.copyWith(isLoading: true);
    try {
      final idin = ref.read(initiateIdinVerificationProvider);
      final url = await idin();
      state = state.copyWith(isLoading: false, redirectUrl: url);
    } on Exception {
      state = state.copyWith(isLoading: false, error: 'error.generic');
    }
  }

  /// Dismiss the prompt (user tapped "Later").
  void dismiss() {
    state = const KycPromptState();
  }
}
