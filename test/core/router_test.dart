import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:deelmarkt/core/router/app_router.dart';
import 'package:deelmarkt/core/router/routes.dart';

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

  group('GoRouter navigation', () {
    late GoRouter router;

    setUp(() {
      router = createRouter();
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
}
