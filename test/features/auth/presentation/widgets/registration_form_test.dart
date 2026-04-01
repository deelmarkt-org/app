import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/auth/presentation/widgets/registration_form.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Wraps [RegistrationForm] in a [MaterialApp] + [Scaffold] so that
  /// [ScaffoldMessenger] and theme are available. No easy_localization setup
  /// is needed because `.tr()` returns the raw key when l10n is not
  /// initialized, which is fine for assertions.
  Widget buildSubject({
    required void Function({
      required String email,
      required String password,
      required bool termsAccepted,
      required bool privacyAccepted,
    })
    onSubmit,
    VoidCallback? onLoginTap,
    bool isLoading = false,
    String? errorText,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: RegistrationForm(
            onSubmit: onSubmit,
            onLoginTap: onLoginTap ?? () {},
            isLoading: isLoading,
            errorText: errorText,
          ),
        ),
      ),
    );
  }

  // No-op default callback for tests that do not care about onSubmit.
  void noOpSubmit({
    required String email,
    required String password,
    required bool termsAccepted,
    required bool privacyAccepted,
  }) {}

  // ---------------------------------------------------------------------------
  // Tests
  // ---------------------------------------------------------------------------

  group('RegistrationForm', () {
    testWidgets('renders email and password fields', (tester) async {
      await tester.pumpWidget(buildSubject(onSubmit: noOpSubmit));

      // DeelInput uses labelText which includes the raw l10n key.
      // The email field label is 'form.email *' (isRequired adds *).
      expect(find.text('form.email *'), findsOneWidget);
      expect(find.text('form.pass_field *'), findsOneWidget);
    });

    testWidgets('shows password strength indicator when typing password', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(onSubmit: noOpSubmit));

      // Strength indicator should not be visible initially.
      expect(find.text('password_strength.weak'), findsNothing);

      // Type into the password field. DeelInput uses TextFormField internally.
      // Find the second TextFormField (password field).
      final passwordFields = find.byType(TextFormField);
      expect(passwordFields, findsAtLeast(2));

      await tester.enterText(passwordFields.at(1), 'abc');
      await tester.pump();

      // A short password should show the weak strength label.
      expect(find.text('password_strength.weak'), findsOneWidget);
    });

    testWidgets('submit button exists', (tester) async {
      await tester.pumpWidget(buildSubject(onSubmit: noOpSubmit));

      // The submit button has label 'auth.create_account'.
      expect(find.text('auth.create_account'), findsOneWidget);
    });

    testWidgets(
      'submit button is disabled when terms and privacy not accepted',
      (tester) async {
        await tester.pumpWidget(buildSubject(onSubmit: noOpSubmit));

        // The DeelButton wraps an ElevatedButton. When onPressed is null
        // (terms/privacy not checked), the button is disabled.
        // Find the ElevatedButton containing the create account label.
        final elevatedButton = find.ancestor(
          of: find.text('auth.create_account'),
          matching: find.byType(ElevatedButton),
        );
        expect(elevatedButton, findsOneWidget);

        final button = tester.widget<ElevatedButton>(elevatedButton);
        expect(button.onPressed, isNull);
      },
    );

    testWidgets('shows error text when errorText is provided', (tester) async {
      await tester.pumpWidget(
        buildSubject(onSubmit: noOpSubmit, errorText: 'error.email_taken'),
      );

      // The error text is displayed via Text(widget.errorText!.tr()).
      // Since l10n is not initialized, .tr() returns the raw key.
      expect(find.text('error.email_taken'), findsOneWidget);
    });

    testWidgets('terms and privacy checkboxes exist', (tester) async {
      await tester.pumpWidget(buildSubject(onSubmit: noOpSubmit));

      // There are exactly 2 CheckboxListTile widgets.
      expect(find.byType(CheckboxListTile), findsNWidgets(2));

      // Both should be unchecked initially.
      final checkboxTiles = tester.widgetList<CheckboxListTile>(
        find.byType(CheckboxListTile),
      );
      for (final tile in checkboxTiles) {
        expect(tile.value, isFalse);
      }
    });

    testWidgets('calls onSubmit with correct params when form is valid and both '
        'checkboxes checked', (tester) async {
      String? capturedEmail;
      String? capturedPassword;
      bool? capturedTerms;
      bool? capturedPrivacy;

      await tester.pumpWidget(
        buildSubject(
          onSubmit: ({
            required String email,
            required String password,
            required bool termsAccepted,
            required bool privacyAccepted,
          }) {
            capturedEmail = email;
            capturedPassword = password;
            capturedTerms = termsAccepted;
            capturedPrivacy = privacyAccepted;
          },
        ),
      );

      // Fill in email.
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'test@example.com');

      // Fill in password (must pass validator: >= 8 chars, upper, lower, digit).
      await tester.enterText(textFields.at(1), 'Pass1234');
      await tester.pump();

      // Check both checkboxes. Use ensureVisible + tap on Checkbox widgets
      // because the CheckboxListTile may be off-screen in the scroll view.
      final checkboxes = find.byType(Checkbox);
      expect(checkboxes, findsAtLeast(2));

      await tester.ensureVisible(checkboxes.at(0));
      await tester.tap(checkboxes.at(0)); // terms
      await tester.pump();

      await tester.ensureVisible(checkboxes.at(1));
      await tester.tap(checkboxes.at(1)); // privacy
      await tester.pump();

      // Tap submit button. Use ensureVisible to scroll it into view.
      final submitButton = find.text('auth.create_account');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pump();

      expect(capturedEmail, 'test@example.com');
      expect(capturedPassword, 'Pass1234');
      expect(capturedTerms, isTrue);
      expect(capturedPrivacy, isTrue);
    });

    testWidgets(
      'submit button becomes enabled after checking both checkboxes',
      (tester) async {
        await tester.pumpWidget(buildSubject(onSubmit: noOpSubmit));

        // Initially disabled.
        final findElevatedButton = find.byWidgetPredicate(
          (w) => w is ElevatedButton,
        );
        // The first ElevatedButton is the submit (create account) button.
        expect(
          tester.widget<ElevatedButton>(findElevatedButton.first).onPressed,
          isNull,
        );

        // Check terms only - still disabled.
        final checkboxes = find.byType(Checkbox);
        await tester.ensureVisible(checkboxes.at(0));
        await tester.tap(checkboxes.at(0));
        await tester.pump();
        expect(
          tester.widget<ElevatedButton>(findElevatedButton.first).onPressed,
          isNull,
        );

        // Check privacy too - now enabled.
        await tester.ensureVisible(checkboxes.at(1));
        await tester.tap(checkboxes.at(1));
        await tester.pump();
        expect(
          tester.widget<ElevatedButton>(findElevatedButton.first).onPressed,
          isNotNull,
        );
      },
    );

    testWidgets('does not call onSubmit with invalid email', (tester) async {
      var submitted = false;

      await tester.pumpWidget(
        buildSubject(
          onSubmit: ({
            required String email,
            required String password,
            required bool termsAccepted,
            required bool privacyAccepted,
          }) {
            submitted = true;
          },
        ),
      );

      // Fill invalid email, valid password.
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'not-an-email');
      await tester.enterText(textFields.at(1), 'Pass1234');
      await tester.pump();

      // Check both checkboxes.
      final checkboxes = find.byType(CheckboxListTile);
      await tester.tap(checkboxes.at(0));
      await tester.pump();
      await tester.tap(checkboxes.at(1));
      await tester.pump();

      // Tap submit.
      await tester.tap(find.text('auth.create_account'));
      await tester.pump();

      expect(submitted, isFalse);
    });

    testWidgets('login link button exists and calls onLoginTap', (
      tester,
    ) async {
      var loginTapped = false;

      await tester.pumpWidget(
        buildSubject(
          onSubmit: noOpSubmit,
          onLoginTap: () => loginTapped = true,
        ),
      );

      // The login link button has label 'auth.already_have_account'.
      final loginButton = find.text('auth.already_have_account');
      expect(loginButton, findsOneWidget);

      await tester.tap(loginButton);
      await tester.pump();

      expect(loginTapped, isTrue);
    });
  });
}
