import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:deelmarkt/features/auth/domain/usecases/check_kyc_required_usecase.dart';
import 'package:deelmarkt/features/auth/domain/usecases/initiate_idin_verification_usecase.dart';
import 'package:deelmarkt/features/auth/presentation/viewmodels/kyc_prompt_viewmodel.dart';
import 'package:deelmarkt/features/profile/domain/entities/user_entity.dart';

class _MockInitiateIdin extends Mock
    implements InitiateIdinVerificationUseCase {}

void main() {
  late KycPromptNotifier notifier;
  late _MockInitiateIdin mockInitiateIdin;

  setUp(() {
    mockInitiateIdin = _MockInitiateIdin();
    notifier = KycPromptNotifier(
      checkKycRequired: const CheckKycRequiredUseCase(),
      initiateIdin: mockInitiateIdin,
    );
  });

  group('KycPromptState', () {
    test('default state has no prompt', () {
      expect(notifier.state.promptType, KycPromptType.none);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.isSuccess, isFalse);
      expect(notifier.state.error, isNull);
    });

    test('copyWith creates new instance with updated fields', () {
      const original = KycPromptState();
      final updated = original.copyWith(
        promptType: KycPromptType.banner,
        isLoading: true,
      );

      expect(updated.promptType, KycPromptType.banner);
      expect(updated.isLoading, isTrue);
      expect(updated.isSuccess, isFalse);
    });

    test('copyWith clears error when not passed', () {
      const state = KycPromptState(error: 'some error');
      final updated = state.copyWith(isLoading: true);

      expect(updated.error, isNull);
    });
  });

  group('KycPromptNotifier', () {
    test('checkRequired sets prompt for level0 user', () {
      notifier.checkRequired(kycLevel: KycLevel.level0);
      expect(notifier.state.promptType, isNot(KycPromptType.none));
    });

    test('checkRequired with level1 and high amount sets prompt', () {
      notifier.checkRequired(
        kycLevel: KycLevel.level1,
        transactionAmountCents: 50000,
      );
      expect(notifier.state.promptType, isNot(KycPromptType.none));
    });

    test('checkRequired sets none for level2 user', () {
      notifier.checkRequired(kycLevel: KycLevel.level2);
      expect(notifier.state.promptType, KycPromptType.none);
    });

    test('checkRequired sets none for level1 with no transaction', () {
      notifier.checkRequired(kycLevel: KycLevel.level1);
      expect(notifier.state.promptType, KycPromptType.none);
    });

    test('initiateIdin sets isSuccess on success', () async {
      when(
        () => mockInitiateIdin.call(),
      ).thenAnswer((_) async => 'https://www.idin.nl/verify');

      await notifier.initiateIdin();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.isSuccess, isTrue);
      expect(notifier.state.error, isNull);
    });

    test('initiateIdin sets error on failure', () async {
      when(() => mockInitiateIdin.call()).thenThrow(Exception('Network error'));

      await notifier.initiateIdin();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, 'error.generic');
    });

    test('dismiss resets state', () {
      notifier.checkRequired(kycLevel: KycLevel.level0);
      expect(notifier.state.promptType, isNot(KycPromptType.none));

      notifier.dismiss();
      expect(notifier.state.promptType, KycPromptType.none);
    });
  });
}
