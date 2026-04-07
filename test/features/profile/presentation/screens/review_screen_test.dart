import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/core/services/shared_prefs_provider.dart';
import 'package:deelmarkt/core/services/supabase_service.dart';
import 'package:deelmarkt/features/profile/presentation/screens/review_screen.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/review_draft_form.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/review_result_view.dart';

User _testUser({String id = 'user-current'}) => User(
  id: id,
  appMetadata: const {},
  userMetadata: const {},
  aud: 'authenticated',
  createdAt: DateTime(2026).toIso8601String(),
);

/// Pumps [ReviewScreen] inside ProviderScope with mock repositories.
///
/// Renders one frame only (no pumpAndSettle) so callers can inspect
/// intermediate states like loading. Callers MUST call
/// `tester.pumpAndSettle(const Duration(seconds: 2))` to drive the
/// async build to completion and avoid pending-timer test failures.
Future<void> _pumpScreen(
  WidgetTester tester,
  String txnId, {
  String userId = 'user-current',
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        useMockDataProvider.overrideWithValue(true),
        sharedPreferencesProvider.overrideWithValue(prefs),
        currentUserProvider.overrideWithValue(_testUser(id: userId)),
      ],
      child: MaterialApp(
        theme: DeelmarktTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: ReviewScreen(transactionId: txnId),
        ),
      ),
    ),
  );
  // Render the first frame — do NOT settle here so callers can see loading.
  await tester.pump();
}

void main() {
  group('ReviewScreen', () {
    testWidgets('shows loading indicator immediately', (tester) async {
      await _pumpScreen(tester, 'txn-001');
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      // Settle to avoid pending-timer assertion at test teardown
      await tester.pumpAndSettle(const Duration(seconds: 2));
    });

    testWidgets('shows AppBar with title', (tester) async {
      await _pumpScreen(tester, 'txn-001');
      expect(find.text('review.title'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    });

    testWidgets('shows draft form after mock repos settle (txn released)', (
      tester,
    ) async {
      await _pumpScreen(tester, 'txn-001');
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(ReviewDraftForm), findsOneWidget);
    });

    testWidgets('shows ineligible view for non-released transaction', (
      tester,
    ) async {
      await _pumpScreen(tester, 'txn-pending');
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(ReviewIneligibleView), findsOneWidget);
    });

    testWidgets('shows ineligible view when transaction not found', (
      tester,
    ) async {
      await _pumpScreen(tester, 'txn-nonexistent');
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(ReviewIneligibleView), findsOneWidget);
    });

    testWidgets('renders without errors in dark theme', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            useMockDataProvider.overrideWithValue(true),
            sharedPreferencesProvider.overrideWithValue(prefs),
            currentUserProvider.overrideWithValue(_testUser()),
          ],
          child: MaterialApp(
            theme: DeelmarktTheme.dark,
            home: const MediaQuery(
              data: MediaQueryData(disableAnimations: true),
              child: ReviewScreen(transactionId: 'txn-001'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(ReviewScreen), findsOneWidget);
    });
  });
}
