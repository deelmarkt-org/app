import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/core/services/shared_prefs_provider.dart';
import 'package:deelmarkt/features/profile/presentation/screens/review_screen.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/review_draft_form.dart';

import '../../../../helpers/pump_app.dart';

User _testUser({String id = 'user-current'}) => User(
  id: id,
  appMetadata: const {},
  userMetadata: const {},
  aud: 'authenticated',
  createdAt: DateTime(2026).toIso8601String(),
);

Future<List<Override>> _mockOverrides() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return [
    useMockDataProvider.overrideWithValue(true),
    sharedPreferencesProvider.overrideWithValue(prefs),
    currentUserProvider.overrideWithValue(_testUser()),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReviewScreen', () {
    testWidgets('shows AppBar with review.title', (tester) async {
      final overrides = await _mockOverrides();

      await pumpTestScreenWithProviders(
        tester,
        const ReviewScreen(transactionId: 'txn-001'),
        overrides: overrides,
      );

      // AppBar renders with l10n key
      expect(find.text('review.title'), findsOneWidget);
    });

    testWidgets(
      'shows ReviewDraftForm after loading for eligible transaction',
      (tester) async {
        final overrides = await _mockOverrides();

        await tester.pumpWidget(
          ProviderScope(
            overrides: overrides,
            child: const MaterialApp(
              home: ReviewScreen(transactionId: 'txn-001'),
            ),
          ),
        );

        // Wait for mock repo delay (1000ms headroom)
        await tester.pump(const Duration(milliseconds: 1200));
        await tester.pumpAndSettle();

        // txn-001 maps to released transaction in mock data → draft state
        expect(find.byType(ReviewDraftForm), findsOneWidget);
      },
    );

    testWidgets('ReviewScreen widget exists in widget tree', (tester) async {
      final overrides = await _mockOverrides();

      await pumpTestScreenWithProviders(
        tester,
        const ReviewScreen(transactionId: 'txn-001'),
        overrides: overrides,
      );

      expect(find.byType(ReviewScreen), findsOneWidget);
    });
  });
}
