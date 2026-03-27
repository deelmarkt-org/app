import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/core/router/app_router.dart';
import 'package:deelmarkt/core/router/auth_guard.dart';
import 'package:deelmarkt/core/router/routes.dart';

/// Creates a test router with pre-set auth state (no real Supabase).
GoRouter _createTestRouter({bool isLoggedIn = false, bool isLoading = false}) {
  final authState =
      isLoading
          ? const AsyncValue<AuthState>.loading()
          : AsyncValue<AuthState>.data(
            AuthState(
              AuthChangeEvent.initialSession,
              isLoggedIn
                  ? Session(
                    accessToken: 'test',
                    tokenType: 'bearer',
                    user: const User(
                      id: 'test-user',
                      appMetadata: {},
                      userMetadata: {},
                      aud: 'authenticated',
                      createdAt: '2026-01-01T00:00:00Z',
                    ),
                  )
                  : null,
            ),
          );

  return createRouter(
    authState: authState,
    authStream: const Stream<AuthState>.empty(),
  );
}

void main() {
  group('AppRoutes', () {
    test('home path is /', () {
      expect(AppRoutes.home, '/');
    });

    test('deep link paths contain :id parameter', () {
      expect(AppRoutes.listingDetail, contains(':id'));
      expect(AppRoutes.userProfile, contains(':id'));
      expect(AppRoutes.transactionDetail, contains(':id'));
      expect(AppRoutes.shippingDetail, contains(':id'));
    });

    test('deep link paths match AASA routes', () {
      expect(AppRoutes.listingDetail, startsWith('/listings/'));
      expect(AppRoutes.userProfile, startsWith('/users/'));
      expect(AppRoutes.transactionDetail, startsWith('/transactions/'));
      expect(AppRoutes.shippingDetail, startsWith('/shipping/'));
    });

    test('tab paths are defined', () {
      expect(AppRoutes.search, '/search');
      expect(AppRoutes.sell, '/sell');
      expect(AppRoutes.messages, '/messages');
      expect(AppRoutes.profile, '/profile');
    });
  });

  group('authRedirect', () {
    test('redirects to splash while loading', () {
      final result = authRedirect(
        isLoading: true,
        isLoggedIn: false,
        currentPath: '/',
      );
      expect(result, '/splash');
    });

    test('redirects protected routes to onboarding when not logged in', () {
      expect(
        authRedirect(isLoading: false, isLoggedIn: false, currentPath: '/sell'),
        '/onboarding',
      );
      expect(
        authRedirect(
          isLoading: false,
          isLoggedIn: false,
          currentPath: '/messages',
        ),
        '/onboarding',
      );
      expect(
        authRedirect(
          isLoading: false,
          isLoggedIn: false,
          currentPath: '/profile',
        ),
        '/onboarding',
      );
    });

    test('allows public routes when not logged in', () {
      expect(
        authRedirect(isLoading: false, isLoggedIn: false, currentPath: '/'),
        isNull,
      );
      expect(
        authRedirect(
          isLoading: false,
          isLoggedIn: false,
          currentPath: '/search',
        ),
        isNull,
      );
    });

    test('redirects auth routes to home when logged in', () {
      expect(
        authRedirect(
          isLoading: false,
          isLoggedIn: true,
          currentPath: '/onboarding',
        ),
        '/',
      );
      expect(
        authRedirect(isLoading: false, isLoggedIn: true, currentPath: '/login'),
        '/',
      );
    });

    test('allows all routes when logged in', () {
      expect(
        authRedirect(isLoading: false, isLoggedIn: true, currentPath: '/sell'),
        isNull,
      );
      expect(
        authRedirect(
          isLoading: false,
          isLoggedIn: true,
          currentPath: '/messages',
        ),
        isNull,
      );
    });
  });

  group('GoRouter navigation', () {
    late GoRouter router;

    setUp(() {
      router = _createTestRouter();
    });

    tearDown(() {
      router.dispose();
    });

    testWidgets('navigates to home on initial load', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsWidgets);
    });

    testWidgets('navigates to listing detail via deep link', (tester) async {
      router.go('/listings/abc-123');
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(find.text('Listing abc-123'), findsWidgets);
    });

    testWidgets('navigates to user profile via deep link', (tester) async {
      router.go('/users/user-456');
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(find.text('User user-456'), findsWidgets);
    });

    testWidgets('navigates to transaction detail via deep link', (
      tester,
    ) async {
      router.go('/transactions/tx-789');
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(find.text('Transaction tx-789'), findsWidgets);
    });

    testWidgets('navigates to shipping detail via deep link', (tester) async {
      router.go('/shipping/ship-012');
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(find.text('Shipping ship-012'), findsWidgets);
    });

    testWidgets('search route receives query param', (tester) async {
      router.go('/search?q=fiets');
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(find.text('Search: fiets'), findsWidgets);
    });

    testWidgets('unknown route shows error page', (tester) async {
      router.go('/nonexistent/path');
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(find.textContaining('Page not found'), findsWidgets);
    });
  });

  group('GoRouter auth guard integration', () {
    testWidgets('redirects /sell to /onboarding when not logged in', (
      tester,
    ) async {
      final router = _createTestRouter(isLoggedIn: false);
      router.go('/sell');
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(
        find.text('app.name'),
        findsWidgets,
      ); // onboarding screen (l10n key)
      router.dispose();
    });

    testWidgets('shows splash while auth is loading', (tester) async {
      final router = _createTestRouter(isLoading: true);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      router.dispose();
    });
  });
}
