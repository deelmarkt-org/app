import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:deelmarkt/features/auth/domain/usecases/check_kyc_required_usecase.dart';
import 'package:deelmarkt/features/auth/domain/usecases/initiate_idin_verification_usecase.dart';
import 'package:deelmarkt/features/auth/presentation/viewmodels/kyc_prompt_viewmodel.dart';
import 'package:deelmarkt/features/auth/presentation/widgets/kyc_bottom_sheet.dart';
import 'package:deelmarkt/features/auth/presentation/widgets/kyc_faq_expandable.dart';
import 'package:deelmarkt/features/auth/presentation/widgets/kyc_progress_bar.dart';
import 'package:deelmarkt/features/auth/presentation/widgets/kyc_trust_footer.dart';

import '../../../../helpers/pump_app.dart';

class MockInitiateIdin extends Mock
    implements InitiateIdinVerificationUseCase {}

void main() {
  late MockInitiateIdin mockInitiateIdin;

  setUp(() {
    mockInitiateIdin = MockInitiateIdin();
    when(
      () => mockInitiateIdin(),
    ).thenAnswer((_) async => 'https://www.idin.nl/verify');
  });

  group('KycBottomSheet', () {
    testWidgets('renders content state with title and subtitle', (
      tester,
    ) async {
      await pumpTestScreenWithProviders(
        tester,
        const Scaffold(body: SingleChildScrollView(child: KycBottomSheet())),
        overrides: [
          kycPromptProvider.overrideWith(
            (ref) => KycPromptNotifier(
              checkKycRequired: const CheckKycRequiredUseCase(),
              initiateIdin: mockInitiateIdin,
            ),
          ),
        ],
      );

      expect(find.text('kyc.sheetTitle'), findsOneWidget);
      expect(find.text('kyc.sheetSubtitle'), findsOneWidget);
    });

    testWidgets('renders KycProgressBar', (tester) async {
      await pumpTestScreenWithProviders(
        tester,
        const Scaffold(body: SingleChildScrollView(child: KycBottomSheet())),
        overrides: [
          kycPromptProvider.overrideWith(
            (ref) => KycPromptNotifier(
              checkKycRequired: const CheckKycRequiredUseCase(),
              initiateIdin: mockInitiateIdin,
            ),
          ),
        ],
      );

      expect(find.byType(KycProgressBar), findsOneWidget);
    });

    testWidgets('renders KycFaqExpandable', (tester) async {
      await pumpTestScreenWithProviders(
        tester,
        const Scaffold(body: SingleChildScrollView(child: KycBottomSheet())),
        overrides: [
          kycPromptProvider.overrideWith(
            (ref) => KycPromptNotifier(
              checkKycRequired: const CheckKycRequiredUseCase(),
              initiateIdin: mockInitiateIdin,
            ),
          ),
        ],
      );

      expect(find.byType(KycFaqExpandable), findsOneWidget);
    });

    testWidgets('renders KycTrustFooter', (tester) async {
      await pumpTestScreenWithProviders(
        tester,
        const Scaffold(body: SingleChildScrollView(child: KycBottomSheet())),
        overrides: [
          kycPromptProvider.overrideWith(
            (ref) => KycPromptNotifier(
              checkKycRequired: const CheckKycRequiredUseCase(),
              initiateIdin: mockInitiateIdin,
            ),
          ),
        ],
      );

      expect(find.byType(KycTrustFooter), findsOneWidget);
    });

    testWidgets('renders verify and later buttons', (tester) async {
      await pumpTestScreenWithProviders(
        tester,
        const Scaffold(body: SingleChildScrollView(child: KycBottomSheet())),
        overrides: [
          kycPromptProvider.overrideWith(
            (ref) => KycPromptNotifier(
              checkKycRequired: const CheckKycRequiredUseCase(),
              initiateIdin: mockInitiateIdin,
            ),
          ),
        ],
      );

      expect(find.text('kyc.verifyWithIdin'), findsOneWidget);
      expect(find.text('kyc.later'), findsOneWidget);
    });

    testWidgets('shows error text when state has error', (tester) async {
      final notifier = KycPromptNotifier(
        checkKycRequired: const CheckKycRequiredUseCase(),
        initiateIdin: mockInitiateIdin,
      );

      when(() => mockInitiateIdin()).thenThrow(Exception('fail'));

      await pumpTestScreenWithProviders(
        tester,
        const Scaffold(body: SingleChildScrollView(child: KycBottomSheet())),
        overrides: [kycPromptProvider.overrideWith((ref) => notifier)],
      );

      await tester.tap(find.text('kyc.verifyWithIdin'));
      await tester.pumpAndSettle();

      expect(find.text('kyc.error'), findsOneWidget);
    });
  });
}
