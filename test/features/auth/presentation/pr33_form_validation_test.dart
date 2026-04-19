import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:deelmarkt/features/auth/domain/entities/registration_state.dart';
import 'package:deelmarkt/features/auth/domain/usecases/register_with_email_usecase.dart';
import 'package:deelmarkt/features/auth/domain/usecases/resend_email_otp_usecase.dart';
import 'package:deelmarkt/features/auth/domain/usecases/send_phone_otp_usecase.dart';
import 'package:deelmarkt/features/auth/domain/usecases/verify_email_otp_usecase.dart';
import 'package:deelmarkt/features/auth/domain/usecases/verify_phone_otp_usecase.dart';
import 'package:deelmarkt/features/auth/presentation/viewmodels/register_viewmodel.dart';
import 'package:deelmarkt/features/auth/presentation/widgets/registration_form.dart';

// ---------------------------------------------------------------------------
// Mocks for ViewModel-level tests
// ---------------------------------------------------------------------------

class MockRegisterWithEmailUseCase extends Mock
    implements RegisterWithEmailUseCase {}

class MockResendEmailOtpUseCase extends Mock implements ResendEmailOtpUseCase {}

class MockVerifyEmailOtpUseCase extends Mock implements VerifyEmailOtpUseCase {}

class MockSendPhoneOtpUseCase extends Mock implements SendPhoneOtpUseCase {}

class MockVerifyPhoneOtpUseCase extends Mock implements VerifyPhoneOtpUseCase {}

// ---------------------------------------------------------------------------
// Fake Notifier for screen-level tests
// ---------------------------------------------------------------------------

class FakeRegisterViewModel extends AutoDisposeNotifier<RegistrationState>
    with Mock
    implements RegisterViewModel {
  FakeRegisterViewModel(this._state);

  final RegistrationState _state;

  @override
  RegistrationState build() => _state;
}

void main() {
  group('Item 3: Terms/privacy checkboxes required before submit', () {
    Widget buildRegistrationForm({
      required void Function({
        required String email,
        required String password,
        required bool termsAccepted,
        required bool privacyAccepted,
      })
      onSubmit,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: RegistrationForm(onSubmit: onSubmit, onLoginTap: () {}),
          ),
        ),
      );
    }

    testWidgets('submit button is disabled when no checkboxes are checked', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildRegistrationForm(
          onSubmit:
              ({
                required email,
                required password,
                required termsAccepted,
                required privacyAccepted,
              }) {},
        ),
      );

      final elevatedButton = find.ancestor(
        of: find.text('auth.create_account'),
        matching: find.byType(ElevatedButton),
      );
      final button = tester.widget<ElevatedButton>(elevatedButton);
      expect(button.onPressed, isNull, reason: 'Button should be disabled');
    });

    testWidgets(
      'submit button is disabled when only terms is checked (privacy missing)',
      (tester) async {
        await tester.pumpWidget(
          buildRegistrationForm(
            onSubmit:
                ({
                  required email,
                  required password,
                  required termsAccepted,
                  required privacyAccepted,
                }) {},
          ),
        );

        // Check terms only
        final checkboxes = find.byType(Checkbox);
        await tester.ensureVisible(checkboxes.at(0));
        await tester.tap(checkboxes.at(0));
        await tester.pump();

        final elevatedButton = find.ancestor(
          of: find.text('auth.create_account'),
          matching: find.byType(ElevatedButton),
        );
        final button = tester.widget<ElevatedButton>(elevatedButton);
        expect(
          button.onPressed,
          isNull,
          reason: 'Button should be disabled with only terms checked',
        );
      },
    );

    testWidgets(
      'submit button is disabled when only privacy is checked (terms missing)',
      (tester) async {
        await tester.pumpWidget(
          buildRegistrationForm(
            onSubmit:
                ({
                  required email,
                  required password,
                  required termsAccepted,
                  required privacyAccepted,
                }) {},
          ),
        );

        // Check privacy only (second checkbox)
        final checkboxes = find.byType(Checkbox);
        await tester.ensureVisible(checkboxes.at(1));
        await tester.tap(checkboxes.at(1));
        await tester.pump();

        final elevatedButton = find.ancestor(
          of: find.text('auth.create_account'),
          matching: find.byType(ElevatedButton),
        );
        final button = tester.widget<ElevatedButton>(elevatedButton);
        expect(
          button.onPressed,
          isNull,
          reason: 'Button should be disabled with only privacy checked',
        );
      },
    );

    testWidgets('submit button becomes enabled when BOTH checkboxes checked', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildRegistrationForm(
          onSubmit:
              ({
                required email,
                required password,
                required termsAccepted,
                required privacyAccepted,
              }) {},
        ),
      );

      // Check both
      final checkboxes = find.byType(Checkbox);
      await tester.ensureVisible(checkboxes.at(0));
      await tester.tap(checkboxes.at(0));
      await tester.pump();
      await tester.ensureVisible(checkboxes.at(1));
      await tester.tap(checkboxes.at(1));
      await tester.pump();

      final elevatedButton = find.ancestor(
        of: find.text('auth.create_account'),
        matching: find.byType(ElevatedButton),
      );
      final button = tester.widget<ElevatedButton>(elevatedButton);
      expect(
        button.onPressed,
        isNotNull,
        reason: 'Button should be enabled with both checkboxes checked',
      );
    });

    testWidgets('two separate checkboxes exist (GDPR Art. 7 compliance)', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildRegistrationForm(
          onSubmit:
              ({
                required email,
                required password,
                required termsAccepted,
                required privacyAccepted,
              }) {},
        ),
      );

      // C-5 fix: Must have 2 SEPARATE checkboxes, not 1 combined
      expect(find.byType(CheckboxListTile), findsNWidgets(2));

      // Both checkboxes should be unchecked initially
      final tiles =
          tester
              .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
              .toList();
      expect(
        tiles[0].value,
        isFalse,
        reason: 'Terms checkbox should start unchecked',
      );
      expect(
        tiles[1].value,
        isFalse,
        reason: 'Privacy checkbox should start unchecked',
      );

      // Terms and Privacy use separate Text widgets inside a Wrap
      // (refactored from Text.rich for WCAG 2.4.4 link semantics).
      // l10n keys are used as fallback text when localization is not loaded.
      expect(
        find.byWidgetPredicate(
          (w) => w is Text && (w.data?.contains('auth.terms') == true),
        ),
        findsWidgets,
        reason: 'Terms checkbox should contain terms text',
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is Text && (w.data?.contains('auth.privacy') == true),
        ),
        findsWidgets,
        reason: 'Privacy checkbox should contain privacy text',
      );
    });

    testWidgets('form validation blocks submit even with checkboxes checked', (
      tester,
    ) async {
      var submitted = false;

      await tester.pumpWidget(
        buildRegistrationForm(
          onSubmit: ({
            required email,
            required password,
            required termsAccepted,
            required privacyAccepted,
          }) {
            submitted = true;
          },
        ),
      );

      // Check both checkboxes
      final checkboxes = find.byType(Checkbox);
      await tester.ensureVisible(checkboxes.at(0));
      await tester.tap(checkboxes.at(0));
      await tester.pump();
      await tester.ensureVisible(checkboxes.at(1));
      await tester.tap(checkboxes.at(1));
      await tester.pump();

      // Leave email and password empty, tap submit
      final submitButton = find.text('auth.create_account');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pump();

      expect(
        submitted,
        isFalse,
        reason: 'Should not submit with empty form fields',
      );
    });
  });
}
