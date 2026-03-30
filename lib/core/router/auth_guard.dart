import 'dart:async';

import 'package:flutter/foundation.dart';

import 'routes.dart';

/// Routes that require authentication — redirect to onboarding if not logged in.
///
/// Note: `/listings/:id` is intentionally NOT protected — listing detail pages
/// are public for SEO and sharing. Auth is required only for actions (buy, message).
const _protectedRoutes = [
  AppRoutes.sell,
  AppRoutes.messages,
  AppRoutes.profile,
  '/transactions',
  '/shipping',
];

/// Routes shown only to unauthenticated users — redirect to home if logged in.
const _authRoutes = ['/onboarding', '/login', '/register'];

/// GoRouter redirect function for authentication state.
///
/// - While auth state is loading → `/splash` (prevents FOUC)
/// - Unauthenticated + onboarding not complete → `/onboarding`
/// - Unauthenticated + onboarding complete + protected route → `/login`
/// - Authenticated + auth route → `/home`
/// - Otherwise → no redirect
String? authRedirect({
  required bool isLoading,
  required bool isLoggedIn,
  required String currentPath,
  bool isOnboardingComplete = false,
}) {
  if (isLoading) return '/splash';

  // After auth resolves, leave the splash screen.
  if (currentPath == '/splash') {
    if (isLoggedIn) return AppRoutes.home;
    return isOnboardingComplete ? AppRoutes.login : AppRoutes.onboarding;
  }

  final isProtected = _protectedRoutes.any(
    (route) => currentPath.startsWith(route),
  );

  if (!isLoggedIn && isProtected) {
    return isOnboardingComplete ? '/login' : '/onboarding';
  }
  if (isLoggedIn && _authRoutes.contains(currentPath)) return AppRoutes.home;

  return null;
}

/// Converts a [Stream] into a [Listenable] for GoRouter.refreshListenable.
///
/// GoRouter re-evaluates redirect on every stream event — used with
/// Supabase auth.onAuthStateChange to react to login/logout.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen(
      (_) => notifyListeners(),
      onError: (Object error) {
        debugPrint('Auth stream error: $error');
      },
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
