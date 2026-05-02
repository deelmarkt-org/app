import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/router/routes.dart';
import 'package:deelmarkt/core/services/supabase_service.dart';
import 'package:deelmarkt/features/admin/presentation/screens/admin_shell_screen.dart';
import 'package:deelmarkt/features/admin/presentation/widgets/admin_narrow_viewport_message.dart';
import 'package:deelmarkt/features/admin/presentation/widgets/admin_sidebar.dart';

// ---------------------------------------------------------------------------
// Fake SupabaseClient — only stubs auth.signOut()
// ---------------------------------------------------------------------------

class _FakeGoTrueClient extends Fake implements GoTrueClient {
  int signOutCalls = 0;
  Duration? signOutDelay;
  Exception? signOutError;

  @override
  Future<void> signOut({SignOutScope scope = SignOutScope.local}) async {
    if (signOutDelay != null) await Future<void>.delayed(signOutDelay!);
    if (signOutError != null) throw signOutError!;
    signOutCalls++;
  }
}

class _FakeSupabaseClient extends Fake implements SupabaseClient {
  _FakeSupabaseClient(this._auth);
  final _FakeGoTrueClient _auth;

  @override
  GoTrueClient get auth => _auth;
}

// ---------------------------------------------------------------------------
// Helper — builds AdminShellScreen wrapped in GoRouter + ProviderScope
// ---------------------------------------------------------------------------

Widget _buildWithRouter({
  required String initialLocation,
  required List<String> navigatedRoutes,
  SupabaseClient? supabaseClient,
  double screenWidth = 900,
}) {
  final fakeAuth = _FakeGoTrueClient();
  final fakeClient = supabaseClient ?? _FakeSupabaseClient(fakeAuth);

  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (context, state, child) => AdminShellScreen(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.admin,
            builder: (context, _) => const Scaffold(body: Text('Dashboard')),
          ),
          GoRoute(
            path: AppRoutes.adminFlaggedListings,
            builder: (context, _) => const Scaffold(body: Text('Flagged')),
          ),
          GoRoute(
            path: AppRoutes.adminReportedUsers,
            builder: (context, _) => const Scaffold(body: Text('Reported')),
          ),
          GoRoute(
            path: AppRoutes.adminDisputes,
            builder: (context, _) => const Scaffold(body: Text('Disputes')),
          ),
          GoRoute(
            path: AppRoutes.adminDsaNotices,
            builder: (context, _) => const Scaffold(body: Text('DSA')),
          ),
          GoRoute(
            path: AppRoutes.adminAppeals,
            builder: (context, _) => const Scaffold(body: Text('Appeals')),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, _) {
          navigatedRoutes.add(AppRoutes.login);
          return const Scaffold(body: Text('Login'));
        },
      ),
    ],
  );

  return ProviderScope(
    overrides: [supabaseClientProvider.overrideWithValue(fakeClient)],
    child: MaterialApp.router(
      theme: DeelmarktTheme.light,
      routerConfig: router,
    ),
  );
}

void main() {
  group('AdminShellScreen', () {
    // ── Viewport breakpoint ──────────────────────────────────────────────────

    testWidgets('wide viewport (≥900px) shows AdminSidebar', (tester) async {
      tester.view.physicalSize = const Size(900, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildWithRouter(initialLocation: AppRoutes.admin, navigatedRoutes: []),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AdminSidebar), findsOneWidget);
      expect(find.byType(AdminNarrowViewportMessage), findsNothing);
    });

    testWidgets('narrow viewport (<900px) shows AdminNarrowViewportMessage', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildWithRouter(
          initialLocation: AppRoutes.admin,
          navigatedRoutes: [],
          screenWidth: 400,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AdminNarrowViewportMessage), findsOneWidget);
      expect(find.byType(AdminSidebar), findsNothing);
    });

    // Boundary regression: confirms the 768→900 raise (PR #269 review)
    // is preserved. 899 must show the narrow message; 900 must show the
    // sidebar. Without this, a future threshold drop to e.g. 800 would
    // pass the looser ≥900 / <900 tests above.
    testWidgets('boundary: 899px narrow, 900px sidebar', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // 899 px → narrow viewport message.
      tester.view.physicalSize = const Size(899, 800);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(
        _buildWithRouter(initialLocation: AppRoutes.admin, navigatedRoutes: []),
      );
      await tester.pumpAndSettle();
      expect(
        find.byType(AdminNarrowViewportMessage),
        findsOneWidget,
        reason: '899 px must be narrow (boundary minus 1)',
      );

      // 900 px → sidebar appears.
      tester.view.physicalSize = const Size(900, 800);
      await tester.pumpWidget(
        _buildWithRouter(initialLocation: AppRoutes.admin, navigatedRoutes: []),
      );
      await tester.pumpAndSettle();
      expect(
        find.byType(AdminSidebar),
        findsOneWidget,
        reason: '900 px must show sidebar (exact boundary)',
      );
    });

    // ── Nav index derivation ─────────────────────────────────────────────────

    testWidgets('_selectedIndex returns 0 for /admin (dashboard)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildWithRouter(initialLocation: AppRoutes.admin, navigatedRoutes: []),
      );
      await tester.pumpAndSettle();

      // selectedIndex == 0 → Dashboard nav tile is selected.
      final sidebar = tester.widget<AdminSidebar>(find.byType(AdminSidebar));
      expect(sidebar.selectedIndex, 0);
    });

    testWidgets('_selectedIndex returns 1 for /admin/flagged-listings', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildWithRouter(
          initialLocation: AppRoutes.adminFlaggedListings,
          navigatedRoutes: [],
        ),
      );
      await tester.pumpAndSettle();

      final sidebar = tester.widget<AdminSidebar>(find.byType(AdminSidebar));
      expect(sidebar.selectedIndex, 1);
    });

    // ── Sign-out ─────────────────────────────────────────────────────────────

    testWidgets('sign out navigates to login after await', (tester) async {
      tester.view.physicalSize = const Size(900, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final navigated = <String>[];
      final fakeAuth = _FakeGoTrueClient();
      final fakeClient = _FakeSupabaseClient(fakeAuth);

      await tester.pumpWidget(
        _buildWithRouter(
          initialLocation: AppRoutes.admin,
          navigatedRoutes: navigated,
          supabaseClient: fakeClient,
        ),
      );
      await tester.pumpAndSettle();

      // Tap the sign-out footer link in the sidebar.
      await tester.tap(find.text('admin.sidebar.sign_out'));
      await tester.pumpAndSettle();

      // Navigation to login must have happened after signOut completed.
      expect(navigated, contains(AppRoutes.login));
      expect(fakeAuth.signOutCalls, 1);
    });

    testWidgets('sign out navigates to login even when signOut throws', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final navigated = <String>[];
      final fakeAuth =
          _FakeGoTrueClient()..signOutError = Exception('network error');
      final fakeClient = _FakeSupabaseClient(fakeAuth);

      // Suppress uncaught-exception logs from the logger during test.
      final origPrint = debugPrint;
      debugPrint = (_, {wrapWidth}) {};

      await tester.pumpWidget(
        _buildWithRouter(
          initialLocation: AppRoutes.admin,
          navigatedRoutes: navigated,
          supabaseClient: fakeClient,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('admin.sidebar.sign_out'));
      await tester.pumpAndSettle();
      debugPrint = origPrint; // restore before _verifyInvariants runs

      // Graceful degradation: even if signOut throws, admin is not stranded.
      expect(navigated, contains(AppRoutes.login));
    });
  });
}
