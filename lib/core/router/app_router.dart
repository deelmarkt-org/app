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
import 'package:deelmarkt/core/services/unleash_service.dart';
import 'package:deelmarkt/core/router/admin_guard.dart' as admin_guard;
import 'package:deelmarkt/core/router/auth_guard.dart';
import 'package:deelmarkt/core/router/routes.dart';
import 'package:deelmarkt/core/router/scaffold_with_nav.dart';
import 'package:deelmarkt/core/router/splash_screen.dart';
import 'package:deelmarkt/features/admin/presentation/screens/admin_shell_screen.dart';
import 'package:deelmarkt/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:deelmarkt/features/profile/domain/entities/sanction_entity.dart';
import 'package:deelmarkt/features/profile/presentation/screens/appeal_screen.dart';
import 'package:deelmarkt/features/profile/presentation/screens/suspension_gate_screen.dart';
import 'package:deelmarkt/features/profile/presentation/viewmodels/active_sanction_provider.dart';

/// Placeholder for admin sub-screens not yet implemented (Phase B-D).
Widget _adminComingSoon(BuildContext context) =>
    Scaffold(body: Center(child: Text('admin.comingSoon'.tr())));

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
  // Re-triggers GoRouter redirect whenever the sanction state changes so the
  // suspension gate activates / deactivates without needing an auth event.
  final sanctionNotifier = _SanctionRefreshNotifier();
  ref
    ..onDispose(sanctionNotifier.dispose)
    ..listen<AsyncValue<SanctionEntity?>>(
      activeSanctionProvider,
      (prev, next) => sanctionNotifier.ping(),
    );

  return _buildRouter(
    authStream: authStream,
    extraListenable: sanctionNotifier,
    redirect: (context, state) {
      // Read auth state at redirect-time (not router-creation-time).
      // When the stream hasn't emitted yet (AsyncValue.loading), fall back
      // to the synchronous current session. GoRouterRefreshStream can miss
      // Supabase's INITIAL_SESSION event when it subscribes after init.
      final authState = ref.read(authStateChangesProvider);
      final supabase = ref.read(supabaseClientProvider);

      // Fix #118: Unified session source — no split-brain between isLoggedIn
      // and currentUser. Both are derived from the same Session object.
      // See docs/adr/ADR-001-reactive-auth-guard.md for full rationale.
      final useReactiveGuard = ref.read(
        isFeatureEnabledProvider(FeatureFlags.authGuardReactive),
      );

      final Session? session =
          authState.isLoading
              ? supabase.auth.currentSession
              : authState.valueOrNull?.session;

      final bool isLoggedIn;
      final User? currentUser;

      if (useReactiveGuard) {
        // New path: validate session expiry and derive both values from Session.
        final isSessionValid = session != null && !_isSessionExpired(session);
        isLoggedIn = isSessionValid;
        currentUser = isSessionValid ? session.user : null;

        // Proactively refresh when within 60s of expiry but still valid.
        if (isSessionValid && session.expiresAt != null) {
          final secondsLeft =
              session.expiresAt! -
              DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
          if (secondsLeft < 60) {
            supabase.auth.refreshSession().catchError((
              Object e,
              StackTrace st,
            ) {
              AppLogger.warning(
                'Proactive session refresh failed',
                tag: 'auth',
                error: e,
              );
              return AuthResponse();
            });
          }
        }
      } else {
        // Legacy path: retained for canary rollback (flag off = original behaviour).
        isLoggedIn =
            authState.isLoading
                ? supabase.auth.currentSession != null
                : authState.valueOrNull?.session != null;
        currentUser = supabase.auth.currentUser; // legacy stale read
      }

      final onboardingComplete =
          ref.read(isOnboardingCompleteProvider).valueOrNull ?? false;

      // P-53 Suspension gate: read active sanction to gate all navigation.
      // Using ref.read here (not watch) because GoRouter re-runs redirect
      // via refreshListenable; use invalidate + notifyListeners to trigger
      // re-evaluation when sanction state changes.
      final sanctionAsync = ref.read(activeSanctionProvider);
      final asyncRedirect = sanctionAsyncRedirect(
        isLoggedIn: isLoggedIn,
        sanctionAsync: sanctionAsync,
        currentPath: state.matchedLocation,
      );
      if (asyncRedirect != null) return asyncRedirect;
      // Treat an error as an active sanction so that authRedirect's
      // _sanctionRedirect does NOT release the user from /suspended while the
      // provider is still in error state (i.e. the redirect-cycle bypass).
      final hasActiveSanction =
          sanctionAsync.hasError ||
          (sanctionAsync.valueOrNull?.isActive ?? false);

      return authRedirect(
        isLoading: false, // Supabase is always initialized before runApp
        isLoggedIn: isLoggedIn,
        currentPath: state.matchedLocation,
        isOnboardingComplete: onboardingComplete,
        isAdmin: admin_guard.isAdmin(currentUser),
        hasActiveSanction: hasActiveSanction,
      );
    },
  );
}

/// Returns true if [session] has expired (or is within 30 s of expiry).
///
/// The 30-second buffer triggers proactive refresh before hard expiry to
/// avoid a scenario where the token expires between the guard check and the
/// actual Supabase API call. Service-role tokens with no expiry return false.
///
/// Only called when [FeatureFlags.authGuardReactive] is enabled.
bool _isSessionExpired(Session session) {
  final expiresAt = session.expiresAt;
  if (expiresAt == null) return false; // no-expiry service token
  final expiry = DateTime.fromMillisecondsSinceEpoch(
    expiresAt * 1000,
    isUtc: true,
  );
  return DateTime.now().toUtc().isAfter(
    expiry.subtract(const Duration(seconds: 30)),
  );
}

/// Maps the current [activeSanctionProvider] [AsyncValue] to a router
/// redirect, enforcing the P-53 suspension gate's loading + error semantics.
///
/// - **Loading + logged in**: hold on `/splash` to prevent a flash of `/home`
///   before the gate can activate.
/// - **Error + logged in**: fail-CLOSED — route to `/suspended`. A
///   suspended/banned user must NOT be able to bypass the gate by forcing
///   the sanction lookup to fail (e.g. dropping the network). The
///   [SuspensionGateScreen] surfaces the error with a retry CTA; a
///   successful retry that resolves to `null` releases the user back to
///   `/home`.
/// - **Data**: returns `null` — the data branch is handled by [authRedirect]
///   via the `hasActiveSanction` flag.
///
/// Reference: Gemini security review on PR #171, comment id 3096148637 —
/// the previous implementation defaulted to `false` on error (fail-OPEN),
/// allowing suspended users through during transport failures.
@visibleForTesting
String? sanctionAsyncRedirect({
  required bool isLoggedIn,
  required AsyncValue<SanctionEntity?> sanctionAsync,
  required String currentPath,
}) {
  if (!isLoggedIn) return null;
  if (sanctionAsync.isLoading &&
      currentPath != AppRoutes.splash &&
      !currentPath.startsWith(AppRoutes.suspended)) {
    return AppRoutes.splash;
  }
  if (sanctionAsync.hasError && !currentPath.startsWith(AppRoutes.suspended)) {
    AppLogger.warning(
      'Sanction lookup failed — fail-closed redirect to /suspended',
      tag: 'router',
      error: sanctionAsync.error,
    );
    return AppRoutes.suspended;
  }
  return null;
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

/// Notifies GoRouter whenever [activeSanctionProvider] changes state.
///
/// Required so that GoRouter re-evaluates the suspension gate redirect when
/// the sanction check completes (loading→data) or when an appeal is resolved.
/// Without this, only auth stream events would trigger re-evaluation, leaving
/// the user stuck on /splash after the sanction provider resolves.
class _SanctionRefreshNotifier extends ChangeNotifier {
  _SanctionRefreshNotifier();

  void ping() => notifyListeners();
}

GoRouter _buildRouter({
  required Stream<AuthState> authStream,
  required GoRouterRedirect redirect,
  Listenable? extraListenable,
}) {
  final authListenable = GoRouterRefreshStream(authStream);
  final refreshListenable =
      extraListenable != null
          ? Listenable.merge([authListenable, extraListenable])
          : authListenable;

  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: refreshListenable,
    redirect: redirect,
    routes: [
      // ── Auth routes (outside shell) ──
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
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

      // ── Suspension gate (P-53) — outside shell, no bottom nav ──
      GoRoute(
        path: AppRoutes.suspended,
        name: 'suspended',
        builder: (context, state) => const SuspensionGateScreen(),
      ),
      GoRoute(
        path: AppRoutes.suspendedAppeal,
        name: 'suspended-appeal',
        builder: (ctx, state) {
          final sanction = state.extra;
          if (sanction is! SanctionEntity) {
            // Missing/invalid extra — bounce back to gate.
            return const SuspensionGateScreen();
          }
          return AppealScreen(sanction: sanction);
        },
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
            builder: (context, state) => _adminComingSoon(context),
          ),
          GoRoute(
            path: AppRoutes.adminReportedUsers,
            name: 'admin-reported-users',
            builder: (context, state) => _adminComingSoon(context),
          ),
          GoRoute(
            path: AppRoutes.adminDisputes,
            name: 'admin-disputes',
            builder: (context, state) => _adminComingSoon(context),
            routes: [
              GoRoute(
                path: ':id',
                name: 'admin-dispute-detail',
                redirect: _idGuard('id', AppRoutes.adminDisputes),
                builder:
                    (context, state) => Scaffold(
                      body: Center(child: Text('admin.comingSoon'.tr())),
                    ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.adminDsaNotices,
            name: 'admin-dsa-notices',
            builder: (context, state) => _adminComingSoon(context),
          ),
          GoRoute(
            path: AppRoutes.adminAppeals,
            name: 'admin-appeals',
            builder: (context, state) => _adminComingSoon(context),
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
