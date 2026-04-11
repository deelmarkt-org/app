// TODO(#133): File exceeds 200-line limit (406 lines). Split into route groups.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/core/constants.dart';
import 'package:deelmarkt/core/services/app_logger.dart';
import 'package:deelmarkt/features/auth/presentation/screens/login_screen.dart';
import 'package:deelmarkt/features/auth/presentation/screens/register_screen.dart';
import 'package:deelmarkt/features/home/presentation/home_screen.dart';
import 'package:deelmarkt/features/home/presentation/screens/category_browse_screen.dart';
import 'package:deelmarkt/features/home/presentation/screens/category_detail_screen.dart';
import 'package:deelmarkt/features/home/presentation/screens/favourites_screen.dart';
import 'package:deelmarkt/features/listing_detail/presentation/listing_detail_screen.dart';
import 'package:deelmarkt/features/messages/presentation/screens/messages_responsive_shell.dart';
import 'package:deelmarkt/features/search/presentation/search_screen.dart';
import 'package:deelmarkt/features/onboarding/presentation/onboarding_notifier.dart';
import 'package:deelmarkt/features/profile/presentation/screens/own_profile_screen.dart';
import 'package:deelmarkt/features/profile/presentation/screens/public_profile_screen.dart';
import 'package:deelmarkt/features/profile/presentation/screens/review_screen.dart';
import 'package:deelmarkt/features/profile/presentation/screens/settings_screen.dart';
import 'package:deelmarkt/features/onboarding/presentation/onboarding_screen.dart';
import 'package:deelmarkt/features/sell/presentation/screens/listing_creation_screen.dart';
import 'package:deelmarkt/features/shipping/presentation/screens/parcel_shop_selector_page.dart';
import 'package:deelmarkt/features/shipping/presentation/screens/shipping_detail_page.dart';
import 'package:deelmarkt/features/shipping/presentation/screens/shipping_qr_page.dart';
import 'package:deelmarkt/features/shipping/presentation/screens/tracking_page.dart';
import 'package:deelmarkt/features/transaction/presentation/screens/transaction_detail_page.dart';
import 'package:deelmarkt/core/services/supabase_service.dart';
import 'package:deelmarkt/core/router/admin_guard.dart' as admin_guard;
import 'package:deelmarkt/core/router/auth_guard.dart';
import 'package:deelmarkt/core/router/routes.dart';
import 'package:deelmarkt/core/router/scaffold_with_nav.dart';
import 'package:deelmarkt/core/router/splash_screen.dart';
import 'package:deelmarkt/features/admin/presentation/screens/admin_shell_screen.dart';
import 'package:deelmarkt/features/admin/presentation/screens/admin_dashboard_screen.dart';

/// Placeholder for admin sub-screens not yet implemented (Phase B-D).
const _adminComingSoon = Scaffold(body: Center(child: Text('Coming soon')));

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
  required Ref ref,
  required Stream<AuthState> authStream,
}) {
  return _buildRouter(
    authStream: authStream,
    redirect: (context, state) {
      // Read auth state at redirect-time (not router-creation-time).
      // When the stream hasn't emitted yet (AsyncValue.loading), fall back
      // to the synchronous current session. GoRouterRefreshStream can miss
      // Supabase's INITIAL_SESSION event when it subscribes after init.
      final authState = ref.read(authStateChangesProvider);
      final supabase = ref.read(supabaseClientProvider);
      // Once Supabase.initialize() has completed, currentSession is available
      // synchronously — use it instead of treating the state as still loading.
      final isLoggedIn =
          authState.isLoading
              ? supabase.auth.currentSession != null
              : authState.valueOrNull?.session != null;
      final onboardingComplete =
          ref.read(isOnboardingCompleteProvider).valueOrNull ?? false;
      final currentUser = supabase.auth.currentUser;
      return authRedirect(
        isLoading: false, // Supabase is always initialized before runApp
        isLoggedIn: isLoggedIn,
        currentPath: state.matchedLocation,
        isOnboardingComplete: onboardingComplete,
        isAdmin: admin_guard.isAdmin(currentUser),
      );
    },
  );
}

/// Test-only factory — accepts a pre-configured redirect function.
@visibleForTesting
GoRouter createTestRouter({
  required GoRouterRedirect redirect,
  Stream<AuthState> authStream = const Stream.empty(),
}) {
  return _buildRouter(authStream: authStream, redirect: redirect);
}

/// Creates a redirect guard that validates a path parameter's length.
///
/// Returns [fallback] when the id is empty or exceeds
/// [AppConstants.maxRouteIdLength]; returns `null` (no redirect) otherwise.
GoRouterRedirect _idGuard(String param, String fallback) {
  return (context, state) {
    final id = state.pathParameters[param] ?? '';
    if (id.isEmpty || id.length > AppConstants.maxRouteIdLength) {
      return fallback;
    }
    return null;
  };
}

GoRouter _buildRouter({
  required Stream<AuthState> authStream,
  required GoRouterRedirect redirect,
}) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: GoRouterRefreshStream(authStream),
    redirect: redirect,
    routes: [
      // ── Auth routes (outside shell) ──
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (_, _) => const RegisterScreen(),
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
                builder: (context, state) => const HomeScreen(),
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
                  return SearchScreen(initialQuery: query);
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.sell,
                name: 'sell',
                builder: (context, state) => const ListingCreationScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.messages,
                name: 'messages',
                builder: (context, state) => const MessagesResponsiveShell(),
                routes: [
                  GoRoute(
                    path: ':conversationId',
                    name: 'chatThread',
                    redirect: _idGuard('conversationId', AppRoutes.messages),
                    builder:
                        (context, state) => MessagesResponsiveShell(
                          conversationId:
                              state.pathParameters['conversationId'],
                        ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                name: 'profile',
                builder: (context, state) => const OwnProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'settings',
                    name: 'settings',
                    builder: (context, state) => const SettingsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // ── Admin panel shell ──
      ShellRoute(
        builder: (context, state, child) => AdminShellScreen(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.admin,
            name: 'admin-dashboard',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminFlaggedListings,
            name: 'admin-flagged-listings',
            builder: (context, state) => _adminComingSoon,
          ),
          GoRoute(
            path: AppRoutes.adminReportedUsers,
            name: 'admin-reported-users',
            builder: (context, state) => _adminComingSoon,
          ),
          GoRoute(
            path: AppRoutes.adminDisputes,
            name: 'admin-disputes',
            builder: (context, state) => _adminComingSoon,
            routes: [
              GoRoute(
                path: ':id',
                name: 'admin-dispute-detail',
                redirect: _idGuard('id', AppRoutes.adminDisputes),
                builder:
                    (context, state) => const Scaffold(
                      body: Center(child: Text('Coming soon')),
                    ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.adminDsaNotices,
            name: 'admin-dsa-notices',
            builder: (context, state) => _adminComingSoon,
          ),
          GoRoute(
            path: AppRoutes.adminAppeals,
            name: 'admin-appeals',
            builder: (context, state) => _adminComingSoon,
          ),
        ],
      ),

      // ── Category & Favourites (outside shell, deep-linkable) ──
      GoRoute(
        path: AppRoutes.categories,
        name: 'categories',
        builder: (context, state) => const CategoryBrowseScreen(),
      ),
      GoRoute(
        path: AppRoutes.categoryDetail,
        name: 'category-detail',
        redirect: _idGuard('id', AppRoutes.categories),
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CategoryDetailScreen(categoryId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.favourites,
        name: 'favourites',
        builder: (context, state) => const FavouritesScreen(),
      ),

      // ── Deep link routes (outside shell) ──
      GoRoute(
        path: AppRoutes.listingDetail,
        name: 'listing-detail',
        redirect: _idGuard('id', AppRoutes.home),
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ListingDetailScreen(listingId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.userProfile,
        name: 'user-profile',
        redirect: _idGuard('id', AppRoutes.home),
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PublicProfileScreen(userId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.transactionDetail,
        name: 'transaction-detail',
        redirect: _idGuard('id', AppRoutes.home),
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TransactionDetailPage(transactionId: id);
        },
        routes: [
          GoRoute(
            path: 'review',
            name: 'transaction-review',
            redirect: _idGuard('id', AppRoutes.home),
            pageBuilder: (context, state) {
              final id = state.pathParameters['id']!;
              return MaterialPage(
                fullscreenDialog: true,
                child: ReviewScreen(transactionId: id),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.shippingDetail,
        name: 'shipping-detail',
        redirect: _idGuard('id', AppRoutes.home),
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ShippingDetailPage(shippingId: id);
        },
        routes: [
          GoRoute(
            path: 'qr',
            name: 'shipping-qr',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ShippingQrPage(shippingId: id);
            },
          ),
          GoRoute(
            path: 'tracking',
            name: 'shipping-tracking',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return TrackingPage(shippingId: id);
            },
          ),
          GoRoute(
            path: 'parcel-shops',
            name: 'parcel-shop-selector',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ParcelShopSelectorPage(shippingId: id);
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) {
      AppLogger.warning(
        'Router: unmatched route',
        tag: 'router',
        error: state.uri.path,
      );
      return _NotFoundScreen(path: state.uri.path);
    },
  );
}

/// 404 error screen — shown for unmatched routes.
class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen({required this.path});

  /// The unmatched route path (shown in debug mode for diagnostics).
  final String path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('error.notFound'.tr())),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'error.notFound'.tr(),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 8),
              Text(path, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
