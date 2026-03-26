import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/onboarding/presentation/onboarding_screen.dart';
import 'auth_guard.dart';
import 'routes.dart';
import 'scaffold_with_nav.dart';
import 'splash_screen.dart';

/// Central GoRouter configuration with deep link support + auth guard.
///
/// Deep link paths handled:
///   /listings/:id     → Listing detail
///   /users/:id        → User profile
///   /transactions/:id → Transaction detail
///   /shipping/:id     → Shipping tracking
///   /search           → Search (with query params)
///   /sell             → Create listing (auth required)
///
/// Auth guard:
///   - /splash shown while auth state loads (prevents FOUC)
///   - Protected routes redirect to /onboarding if not logged in
///   - /onboarding redirects to /home if already logged in
///
/// See .well-known/apple-app-site-association and
/// .well-known/assetlinks.json for the matching host config.
GoRouter createRouter({
  required AsyncValue<AuthState> authState,
  required Stream<AuthState> authStream,
}) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: GoRouterRefreshStream(authStream),
    redirect:
        (context, state) => authRedirect(
          isLoading: authState.isLoading,
          isLoggedIn: authState.valueOrNull?.session != null,
          currentPath: state.matchedLocation,
        ),
    routes: [
      // ── Auth routes (outside shell) ──
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (_, _) => const OnboardingScreen(),
      ),

      // ── Bottom navigation shell ──
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNav(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: 'home',
                builder:
                    (context, state) =>
                        const _Placeholder('Home'), // l10n: P-task
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.search,
                name: 'search',
                builder: (context, state) {
                  final query = state.uri.queryParameters['q'] ?? '';
                  return _Placeholder('Search: $query'); // l10n: P-task
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.sell,
                name: 'sell',
                builder:
                    (context, state) =>
                        const _Placeholder('Sell'), // l10n: P-task
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.messages,
                name: 'messages',
                builder:
                    (context, state) =>
                        const _Placeholder('Messages'), // l10n: P-task
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                name: 'profile',
                builder:
                    (context, state) =>
                        const _Placeholder('Profile'), // l10n: P-task
              ),
            ],
          ),
        ],
      ),

      // ── Deep link routes (outside shell) ──
      GoRoute(
        path: AppRoutes.listingDetail,
        name: 'listing-detail',
        redirect: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          if (id.isEmpty) return AppRoutes.home;
          return null;
        },
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return _Placeholder('Listing $id');
        },
      ),
      GoRoute(
        path: AppRoutes.userProfile,
        name: 'user-profile',
        redirect: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          if (id.isEmpty) return AppRoutes.home;
          return null;
        },
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return _Placeholder('User $id');
        },
      ),
      GoRoute(
        path: AppRoutes.transactionDetail,
        name: 'transaction-detail',
        redirect: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          if (id.isEmpty) return AppRoutes.home;
          return null;
        },
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return _Placeholder('Transaction $id');
        },
      ),
      GoRoute(
        path: AppRoutes.shippingDetail,
        name: 'shipping-detail',
        redirect: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          if (id.isEmpty) return AppRoutes.home;
          return null;
        },
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return _Placeholder('Shipping $id');
        },
        routes: [
          GoRoute(
            path: 'qr',
            name: 'shipping-qr',
            builder: (context, state) {
              // Phase 2 (belengaz): replace with ShippingQrScreen when ViewModel + data layer exists.
              final id = state.pathParameters['id']!;
              return _Placeholder('Shipping QR $id');
            },
          ),
          GoRoute(
            path: 'tracking',
            name: 'shipping-tracking',
            builder: (context, state) {
              // Phase 2 (belengaz): replace with TrackingScreen when ViewModel + data layer exists.
              final id = state.pathParameters['id']!;
              return _Placeholder('Tracking $id');
            },
          ),
          GoRoute(
            path: 'parcel-shops',
            name: 'parcel-shop-selector',
            builder: (context, state) {
              // Wire to ParcelShopSelectorScreen when ViewModel + data layer exist (E05 Phase 2)
              final id = state.pathParameters['id']!;
              return _Placeholder('Parcel Shops $id');
            },
          ),
        ],
      ),
    ],
    errorBuilder:
        (context, state) => _Placeholder('Page not found: ${state.uri.path}'),
  );
}

/// Temporary placeholder screen — replaced by real screens in E01–E06.
class _Placeholder extends StatelessWidget {
  const _Placeholder(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(
        child: Text(label, style: Theme.of(context).textTheme.headlineMedium),
      ),
    );
  }
}
