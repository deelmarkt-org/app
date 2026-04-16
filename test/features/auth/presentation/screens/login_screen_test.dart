import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/features/auth/domain/entities/auth_result.dart';
import 'package:deelmarkt/features/auth/domain/repositories/auth_repository.dart';
import 'package:deelmarkt/features/auth/presentation/screens/login_screen.dart';
import 'package:deelmarkt/features/auth/presentation/view_models/login_view_model.dart';
import 'package:deelmarkt/features/auth/presentation/viewmodels/auth_providers.dart';

import '../../../../helpers/a11y_touch_target_utils.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(OAuthProvider.google);
  });

  setUp(() {
    mockRepo = MockAuthRepository();
    // Default: OAuth cancelled (silent) — avoids Supabase in social button tests.
    when(
      () => mockRepo.loginWithOAuth(any()),
    ).thenAnswer((_) async => const AuthFailureOAuthCancelled());
  });

  /// Pump LoginScreen with a pre-seeded LoginState via override.
  ///
  /// Always overrides the ViewModel to avoid Supabase initialization.
  Future<void> pumpLoginScreen(
    WidgetTester tester, {
    LoginState? initialState,
    ThemeData? theme,
  }) async {
    final overrides = <Override>[
      loginViewModelProvider.overrideWith(() {
        return _FakeLoginViewModel(initialState ?? const LoginState());
      }),
      authRepositoryProvider.overrideWithValue(mockRepo),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          theme: theme ?? DeelmarktTheme.light,
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('LoginScreen — rendering', () {
    testWidgets('renders all main elements', (tester) async {
      await pumpLoginScreen(tester);

      // Logo text
      expect(find.text('DeelMarkt'), findsOneWidget);

      // Welcome text (l10n keys shown as-is in tests)
      expect(find.text('auth.welcomeBack'), findsOneWidget);
      expect(find.text('auth.welcomeSubtitle'), findsOneWidget);

      // Social login stubs
      expect(find.text('auth.continueWithGoogle'), findsOneWidget);
      expect(find.text('auth.continueWithApple'), findsOneWidget);

      // Divider
      expect(find.text('auth.or'), findsOneWidget);

      // Form fields
      expect(find.text('form.email'), findsOneWidget);
      expect(find.text('form.pass_field'), findsOneWidget);

      // Buttons and links
      expect(find.text('auth.logIn'), findsOneWidget);
      expect(find.text('auth.forgotPassword'), findsOneWidget);
      expect(find.text('auth.newToDeelMarkt'), findsOneWidget);
      expect(find.text('auth.create_account'), findsOneWidget);
    });

    testWidgets('biometric section hidden when not available', (tester) async {
      await pumpLoginScreen(tester);

      expect(find.text('auth.useFaceId'), findsNothing);
      expect(find.text('auth.useFingerprint'), findsNothing);
    });

    testWidgets('biometric section visible with face ID', (tester) async {
      await pumpLoginScreen(
        tester,
        initialState: const LoginState(
          biometricAvailable: true,
          biometricMethod: BiometricMethod.face,
        ),
      );

      expect(find.text('auth.useFaceId'), findsOneWidget);
    });

    testWidgets('biometric section visible with fingerprint', (tester) async {
      await pumpLoginScreen(
        tester,
        initialState: const LoginState(
          biometricAvailable: true,
          biometricMethod: BiometricMethod.fingerprint,
        ),
      );

      expect(find.text('auth.useFingerprint'), findsOneWidget);
    });
  });

  group('LoginScreen — inline errors', () {
    testWidgets('shows password error on invalid credentials', (tester) async {
      await pumpLoginScreen(
        tester,
        initialState: const LoginState(
          fieldErrors: LoginFieldErrors(
            passwordError:
                'auth.invalidCredentials', // pragma: allowlist secret
          ),
        ),
      );

      expect(find.text('auth.invalidCredentials'), findsOneWidget);
    });

    testWidgets('shows email validation error', (tester) async {
      await pumpLoginScreen(
        tester,
        initialState: const LoginState(
          fieldErrors: LoginFieldErrors(emailError: 'validation.email_invalid'),
        ),
      );

      expect(find.text('validation.email_invalid'), findsOneWidget);
    });
  });

  group('LoginScreen — loading state', () {
    testWidgets('login button shows loading state', (tester) async {
      // Use pump() not pumpAndSettle() — CircularProgressIndicator
      // has an infinite animation that prevents settle.
      final overrides = <Override>[
        loginViewModelProvider.overrideWith(() {
          return _FakeLoginViewModel(const LoginState(isLoading: true));
        }),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: MaterialApp(
            theme: DeelmarktTheme.light,
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('LoginScreen — dark mode', () {
    testWidgets('renders in dark mode without errors', (tester) async {
      await pumpLoginScreen(tester, theme: DeelmarktTheme.dark);

      expect(find.text('auth.welcomeBack'), findsOneWidget);
      expect(find.text('auth.logIn'), findsOneWidget);
    });

    testWidgets('renders all elements in dark mode', (tester) async {
      await pumpLoginScreen(tester, theme: DeelmarktTheme.dark);

      expect(find.text('DeelMarkt'), findsOneWidget);
      expect(find.text('auth.welcomeSubtitle'), findsOneWidget);
      expect(find.text('auth.continueWithGoogle'), findsOneWidget);
      expect(find.text('auth.continueWithApple'), findsOneWidget);
      expect(find.text('auth.or'), findsOneWidget);
      expect(find.text('form.email'), findsOneWidget);
      expect(find.text('form.pass_field'), findsOneWidget);
      expect(find.text('auth.forgotPassword'), findsOneWidget);
      expect(find.text('auth.newToDeelMarkt'), findsOneWidget);
      expect(find.text('auth.create_account'), findsOneWidget);
    });

    testWidgets('biometric section renders in dark mode', (tester) async {
      await pumpLoginScreen(
        tester,
        theme: DeelmarktTheme.dark,
        initialState: const LoginState(
          biometricAvailable: true,
          biometricMethod: BiometricMethod.face,
        ),
      );

      expect(find.text('auth.useFaceId'), findsOneWidget);
    });

    testWidgets('biometric fingerprint renders in dark mode', (tester) async {
      await pumpLoginScreen(
        tester,
        theme: DeelmarktTheme.dark,
        initialState: const LoginState(
          biometricAvailable: true,
          biometricMethod: BiometricMethod.fingerprint,
        ),
      );

      expect(find.text('auth.useFingerprint'), findsOneWidget);
    });

    testWidgets('error states render in dark mode', (tester) async {
      await pumpLoginScreen(
        tester,
        theme: DeelmarktTheme.dark,
        initialState: const LoginState(
          fieldErrors: LoginFieldErrors(
            emailError: 'validation.email_invalid',
            passwordError:
                'auth.invalidCredentials', // pragma: allowlist secret
          ),
        ),
      );

      expect(find.text('validation.email_invalid'), findsOneWidget);
      expect(find.text('auth.invalidCredentials'), findsOneWidget);
    });

    testWidgets('loading state renders in dark mode', (tester) async {
      final overrides = <Override>[
        loginViewModelProvider.overrideWith(() {
          return _FakeLoginViewModel(const LoginState(isLoading: true));
        }),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: MaterialApp(
            theme: DeelmarktTheme.dark,
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('LoginScreen — expanded layout', () {
    testWidgets('wraps content in Card on expanded screens', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await pumpLoginScreen(tester);

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('no Card on compact screens', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await pumpLoginScreen(tester);

      expect(find.byType(Card), findsNothing);
    });
  });

  group('LoginScreen — social login buttons', () {
    testWidgets('Google button calls loginWithOAuth and is silent on cancel', (
      tester,
    ) async {
      await pumpLoginScreen(tester);

      await tester.tap(find.text('auth.continueWithGoogle'));
      await tester.pumpAndSettle();

      verify(() => mockRepo.loginWithOAuth(OAuthProvider.google)).called(1);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('Apple button calls loginWithOAuth and is silent on cancel', (
      tester,
    ) async {
      await pumpLoginScreen(tester);

      await tester.tap(find.text('auth.continueWithApple'));
      await tester.pumpAndSettle();

      verify(() => mockRepo.loginWithOAuth(OAuthProvider.apple)).called(1);
      expect(find.byType(SnackBar), findsNothing);
    });
  });

  group('LoginScreen — _handleAuthResult error snackbars', () {
    /// Pumps screen with a [_MutableFakeLoginViewModel], then triggers
    /// [_handleAuthResult] by updating the notifier's state.
    Future<void> pumpAndSetResult(
      WidgetTester tester,
      AuthResult result,
    ) async {
      late _MutableFakeLoginViewModel notifier;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            loginViewModelProvider.overrideWith(() {
              return notifier = _MutableFakeLoginViewModel();
            }),
            authRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pumpAndSettle();

      notifier.setResult(result);
      await tester.pumpAndSettle();
    }

    testWidgets('shows network error SnackBar', (tester) async {
      await pumpAndSetResult(
        tester,
        const AuthFailureNetworkError(message: 'err'),
      );

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('shows rate limited SnackBar', (tester) async {
      await pumpAndSetResult(
        tester,
        const AuthFailureRateLimited(retryAfter: Duration(minutes: 5)),
      );

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('shows session expired SnackBar', (tester) async {
      await pumpAndSetResult(tester, const AuthFailureSessionExpired());

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('shows biometric failed SnackBar', (tester) async {
      await pumpAndSetResult(tester, const AuthFailureBiometricFailed());

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('shows generic SnackBar for BiometricUnavailable', (
      tester,
    ) async {
      await pumpAndSetResult(tester, const AuthFailureBiometricUnavailable());

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('shows generic SnackBar for AuthFailureUnknown', (
      tester,
    ) async {
      await pumpAndSetResult(
        tester,
        const AuthFailureUnknown(message: 'unexpected'),
      );

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('OAuthCancelled result is silent — no SnackBar', (
      tester,
    ) async {
      await pumpAndSetResult(tester, const AuthFailureOAuthCancelled());

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('OAuthUnavailable result is silent — no SnackBar', (
      tester,
    ) async {
      await pumpAndSetResult(tester, const AuthFailureOAuthUnavailable());

      expect(find.byType(SnackBar), findsNothing);
    });
  });

  group('LoginScreen — accessibility', () {
    testWidgets('login button meets minimum touch target', (tester) async {
      await pumpLoginScreen(tester);

      final loginButton = find.text('auth.logIn');
      expect(loginButton, findsOneWidget);

      // DeelButton large is 52px height — exceeds 44px minimum
      expectMeetsMinTouchTarget(
        tester,
        find
            .ancestor(of: loginButton, matching: find.byType(ElevatedButton))
            .first,
      );
    });
  });
}

/// Fake ViewModel that returns a pre-set state without side effects.
class _FakeLoginViewModel extends LoginViewModel {
  _FakeLoginViewModel(this._initialState);
  final LoginState _initialState;

  @override
  LoginState build() => _initialState;

  @override
  Future<void> init() async {}

  @override
  Future<void> submitLogin() async {}

  @override
  Future<void> loginWithBiometric({required String localizedReason}) async {}
}

/// Mutable fake that exposes [setResult] so tests can trigger [ref.listen].
class _MutableFakeLoginViewModel extends LoginViewModel {
  @override
  LoginState build() => const LoginState();

  @override
  Future<void> init() async {}

  @override
  Future<void> submitLogin() async {}

  @override
  Future<void> loginWithBiometric({required String localizedReason}) async {}

  void setResult(AuthResult result) {
    state = state.copyWith(lastResult: () => result);
  }
}
