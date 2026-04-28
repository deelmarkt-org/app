import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/l10n/l10n.dart';
import 'package:deelmarkt/core/router/app_router.dart';
import 'package:deelmarkt/core/services/firebase_service.dart';
import 'package:deelmarkt/core/services/performance/performance_tracer_provider.dart';
import 'package:deelmarkt/core/services/performance/trace_names.dart';
import 'package:deelmarkt/core/services/sentry_service.dart';
import 'package:deelmarkt/core/services/supabase_service.dart';
import 'package:deelmarkt/core/services/shared_prefs_provider.dart';
import 'package:deelmarkt/core/services/theme_mode_notifier.dart';
import 'package:deelmarkt/core/services/image_cache_manager.dart';
import 'package:deelmarkt/core/services/unleash_service.dart';

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

  // Cap decoded-image memory before any images load (ADR-022).
  DeelCacheManager.configureMemoryCache();

  // Sentry first — so it captures errors from other service inits AND so the
  // app_start trace below has a real Sentry hub to attach to. Starting the
  // trace before initSentry() returns a NoOpHub span that is silently
  // discarded, so the measurement must follow Sentry init (PR #247 review).
  await initSentry();

  // Start app_start trace immediately after Sentry is ready so the measurement
  // captures the dominant service-init cost (Future.wait below) — the SLO
  // boundary defined in PLAN-P56 §3.5 + trace-registry.md. The container
  // created here is handed to runApp via UncontrolledProviderScope so the
  // trace handle is read by the same scope the widget tree uses.
  final container = ProviderContainer();
  final appStartHandle = container
      .read(performanceTracerProvider)
      .start(TraceNames.appStart);

  try {
    await Future.wait([
      EasyLocalization.ensureInitialized(),
      initSupabase(),
      initFirebase(),
      initUnleash(),
      initSharedPreferences(),
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

    // First post-frame callback fires after the root navigator's first paint
    // — the SLO boundary defined in trace-registry.md for app_start.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(appStartHandle.stop());
    });

    runApp(
      EasyLocalization(
        supportedLocales: AppLocales.supportedLocales,
        fallbackLocale: AppLocales.fallbackLocale,
        path: AppLocales.path,
        child: UncontrolledProviderScope(
          container: container,
          child: const DeelMarktApp(),
        ),
      ),
    );
  } catch (e) {
    // If anything between container creation and runApp throws, the
    // UncontrolledProviderScope never mounts and would leak both the
    // container and the open trace span. Stop the trace and dispose the
    // container explicitly, then rethrow so Sentry/error handlers still
    // see it.
    unawaited(appStartHandle.stop());
    container.dispose();
    rethrow;
  }
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
      themeMode: ref.watch(themeModeNotifierProvider),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      routerConfig: router,
    );
  }
}
