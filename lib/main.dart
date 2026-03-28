import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/design_system/spacing.dart';
import 'core/design_system/theme.dart';
import 'core/l10n/l10n.dart';
import 'core/router/app_router.dart';
import 'core/services/firebase_service.dart';
import 'core/services/supabase_service.dart';
import 'core/services/unleash_service.dart';

/// Fatal error message shown when app crashes before l10n is available.
/// NL + EN fallback — extracted for testing and accessibility.
const kFatalErrorMessage =
    'Er ging iets mis. Start de app opnieuw.\n'
    'Something went wrong. Please restart the app.';

/// Riverpod provider for GoRouter — single instance, auth-aware.
///
/// Passes `ref` to the router so the redirect function reads auth state
/// at redirect-time (not router-creation-time). GoRouterRefreshStream
/// triggers re-evaluation on every auth event without rebuilding the router.
final routerProvider = Provider((ref) {
  final authStream = ref.read(supabaseClientProvider).auth.onAuthStateChange;
  return createRouter(ref: ref, authStream: authStream);
});

void main() async {
  // Remove /#/ from web URLs — must be before WidgetsFlutterBinding.
  usePathUrlStrategy();

  WidgetsFlutterBinding.ensureInitialized();

  // Web error boundary — catch unhandled errors, report to Crashlytics.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    }
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
    return true;
  };

  await Future.wait([
    EasyLocalization.ensureInitialized(),
    initSupabase(),
    initFirebase(),
    initUnleash(),
  ]);

  // Production error widget — user-friendly instead of white screen.
  // Note: ErrorWidget fires before MaterialApp/localization, so l10n is
  // unavailable here. A minimal NL fallback is acceptable (§3.3 exception).
  if (!kDebugMode) {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.s6),
              child: Semantics(
                label: kFatalErrorMessage,
                child: const Text(
                  kFatalErrorMessage,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      );
    };
  }

  runApp(
    EasyLocalization(
      supportedLocales: AppLocales.supportedLocales,
      fallbackLocale: AppLocales.fallbackLocale,
      path: AppLocales.path,
      child: const ProviderScope(child: DeelMarktApp()),
    ),
  );
}

class DeelMarktApp extends ConsumerWidget {
  const DeelMarktApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => 'app.name'.tr(),
      debugShowCheckedModeBanner: false,
      theme: DeelmarktTheme.light,
      darkTheme: DeelmarktTheme.dark,
      themeMode: ThemeMode.system,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      routerConfig: router,
    );
  }
}
