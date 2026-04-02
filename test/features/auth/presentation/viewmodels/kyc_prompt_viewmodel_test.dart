import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:deelmarkt/features/auth/domain/usecases/initiate_idin_verification_usecase.dart';
import 'package:deelmarkt/features/auth/domain/usecases/check_kyc_required_usecase.dart';
import 'package:deelmarkt/features/auth/presentation/viewmodels/kyc_prompt_viewmodel.dart';
import 'package:deelmarkt/features/profile/domain/entities/user_entity.dart';

class _MockInitiateIdin extends Mock
    implements InitiateIdinVerificationUseCase {}

void main() {
  late _MockInitiateIdin mockInitiateIdin;
  late ProviderContainer container;

  setUp(() {
    mockInitiateIdin = _MockInitiateIdin();
    container = ProviderContainer(
      overrides: [
        initiateIdinVerificationProvider.overrideWithValue(mockInitiateIdin),
      ],
    )..listen(kycPromptNotifierProvider, (_, _) {});
  });

  tearDown(() => container.dispose());

  group('KycPromptState', () {
    test('default state has no prompt', () {
      final state = container.read(kycPromptNotifierProvider);
      expect(state.promptType, KycPromptType.none);
      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isFalse);
      expect(state.error, isNull);
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
      container
          .read(kycPromptNotifierProvider.notifier)
          .checkRequired(kycLevel: KycLevel.level0);
      final state = container.read(kycPromptNotifierProvider);
      expect(state.promptType, isNot(KycPromptType.none));
    });

    test('checkRequired with level1 and high amount sets prompt', () {
      container
          .read(kycPromptNotifierProvider.notifier)
          .checkRequired(
            kycLevel: KycLevel.level1,
            transactionAmountCents: 50000,
          );
      final state = container.read(kycPromptNotifierProvider);
      expect(state.promptType, isNot(KycPromptType.none));
    });

    test('checkRequired sets none for level2 user', () {
      container
          .read(kycPromptNotifierProvider.notifier)
          .checkRequired(kycLevel: KycLevel.level2);
      final state = container.read(kycPromptNotifierProvider);
      expect(state.promptType, KycPromptType.none);
    });

    test('checkRequired sets none for level1 with no transaction', () {
      container
          .read(kycPromptNotifierProvider.notifier)
          .checkRequired(kycLevel: KycLevel.level1);
      final state = container.read(kycPromptNotifierProvider);
      expect(state.promptType, KycPromptType.none);
    });

    test('initiateIdin captures redirectUrl on success', () async {
      when(
        () => mockInitiateIdin.call(),
      ).thenAnswer((_) async => 'https://www.idin.nl/verify');

      await container.read(kycPromptNotifierProvider.notifier).initiateIdin();

      final state = container.read(kycPromptNotifierProvider);
      expect(state.isLoading, isFalse);
      expect(state.redirectUrl, 'https://www.idin.nl/verify');
      expect(state.error, isNull);
    });

    test('initiateIdin sets error on failure', () async {
      when(() => mockInitiateIdin.call()).thenThrow(Exception('Network error'));

      await container.read(kycPromptNotifierProvider.notifier).initiateIdin();

      final state = container.read(kycPromptNotifierProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, 'error.generic');
    });

    test('dismiss resets state', () {
      container
          .read(kycPromptNotifierProvider.notifier)
          .checkRequired(kycLevel: KycLevel.level0);
      expect(
        container.read(kycPromptNotifierProvider).promptType,
        isNot(KycPromptType.none),
      );

      container.read(kycPromptNotifierProvider.notifier).dismiss();
      expect(
        container.read(kycPromptNotifierProvider).promptType,
        KycPromptType.none,
      );
    });
  });
}
