import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:deelmarkt/features/auth/domain/entities/registration_state.dart';
import 'package:deelmarkt/features/auth/presentation/screens/register_screen.dart';
import 'package:deelmarkt/features/auth/presentation/viewmodels/register_viewmodel.dart';

// ---------------------------------------------------------------------------
// Fake Notifier
// ---------------------------------------------------------------------------

/// A fake [RegisterViewModel] whose state we can set directly.
///
/// Riverpod's [AutoDisposeNotifier] requires `build()` to return
/// the initial state. We override it to return our test state.
class FakeRegisterViewModel extends AutoDisposeNotifier<RegistrationState>
    with Mock
    implements RegisterViewModel {
  FakeRegisterViewModel(this._state);

  final RegistrationState _state;

  @override
  RegistrationState build() => _state;
}

void main() {
  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Builds the [RegisterScreen] wrapped in a [ProviderScope] with an
  /// overridden [registerViewModelProvider] that emits [state].
  ///
  /// Also wraps in [MaterialApp] with a simple [GoRouter]-like navigator
  /// so that `context.go` does not crash. We use `onGenerateRoute` as a
  /// catch-all so navigation calls do not throw.
  Widget buildSubject(FakeRegisterViewModel fakeViewModel) {
    return ProviderScope(
      overrides: [registerViewModelProvider.overrideWith(() => fakeViewModel)],
      child: MaterialApp(
        home: const RegisterScreen(),
        onGenerateRoute:
            (_) => MaterialPageRoute<void>(builder: (_) => const Scaffold()),
      ),
    );
  }

  group('RegisterScreen', () {
    testWidgets('shows RegistrationForm when step is emailForm', (
      tester,
    ) async {
      final fakeVm = FakeRegisterViewModel(RegistrationState.initial());

      await tester.pumpWidget(buildSubject(fakeVm));

      // The RegistrationForm renders the 'auth.register' heading
      // and the 'auth.create_account' submit button.
      expect(find.text('auth.create_account'), findsOneWidget);

      // The email and password fields should be present.
      expect(find.text('form.email *'), findsOneWidget);
      expect(find.text('form.pass_field *'), findsOneWidget);
    });

    testWidgets('does not show back button on emailForm step', (tester) async {
      final fakeVm = FakeRegisterViewModel(RegistrationState.initial());

      await tester.pumpWidget(buildSubject(fakeVm));

      // No arrow_back icon should appear on the emailForm step.
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('shows back button when not on emailForm step', (tester) async {
      final state = RegistrationState.initial().copyWith(
        step: RegistrationStep.emailVerification,
        email: 'test@example.com',
      );
      final fakeVm = FakeRegisterViewModel(state);

      await tester.pumpWidget(buildSubject(fakeVm));

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('calls goBack when back button is pressed', (tester) async {
      final state = RegistrationState.initial().copyWith(
        step: RegistrationStep.emailVerification,
        email: 'test@example.com',
      );
      final fakeVm = FakeRegisterViewModel(state);

      await tester.pumpWidget(buildSubject(fakeVm));

      // Tap the back button.
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();

      verify(() => fakeVm.goBack()).called(1);
    });

    testWidgets('shows OTP view on emailVerification step', (tester) async {
      final state = RegistrationState.initial().copyWith(
        step: RegistrationStep.emailVerification,
        email: 'test@example.com',
      );
      final fakeVm = FakeRegisterViewModel(state);

      await tester.pumpWidget(buildSubject(fakeVm));

      // The OTP verification view shows the email verification title.
      expect(find.text('auth.verify_email_title'), findsAtLeast(1));

      // The RegistrationForm submit button should NOT be present.
      expect(find.text('auth.create_account'), findsNothing);
    });

    testWidgets('shows phone form on phoneForm step', (tester) async {
      final state = RegistrationState.initial().copyWith(
        step: RegistrationStep.phoneForm,
        email: 'test@example.com',
      );
      final fakeVm = FakeRegisterViewModel(state);

      await tester.pumpWidget(buildSubject(fakeVm));

      // The phone form shows the send code button.
      expect(find.text('auth.send_code'), findsOneWidget);
      expect(find.text('auth.create_account'), findsNothing);
    });

    testWidgets('shows back button on phoneForm step', (tester) async {
      final state = RegistrationState.initial().copyWith(
        step: RegistrationStep.phoneForm,
        email: 'test@example.com',
      );
      final fakeVm = FakeRegisterViewModel(state);

      await tester.pumpWidget(buildSubject(fakeVm));

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets(
      'wraps content in a Card at expanded viewport (>=840px) — matches '
      'docs/screens/01-auth/02-registration.md §Expanded',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fakeVm = FakeRegisterViewModel(RegistrationState.initial());
        await tester.pumpWidget(buildSubject(fakeVm));

        // Card only exists when _buildResponsiveContent takes the expanded
        // branch; LoginScreen + SuspensionGate use the same pattern.
        expect(find.byType(Card), findsOneWidget);
      },
    );

    testWidgets('does NOT wrap in a Card at compact viewport (<840px)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeVm = FakeRegisterViewModel(RegistrationState.initial());
      await tester.pumpWidget(buildSubject(fakeVm));

      expect(find.byType(Card), findsNothing);
    });
  });
}
