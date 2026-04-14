/// Widget tests for [AppealScreen] (P-53 Phase G).
///
/// Reference: lib/features/profile/presentation/screens/appeal_screen.dart
library;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/services/analytics/sanction_analytics.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/profile/domain/entities/sanction_entity.dart';
import 'package:deelmarkt/features/profile/domain/repositories/sanction_repository.dart';
import 'package:deelmarkt/features/profile/presentation/screens/appeal_screen.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/appeal_parts.dart';

import '../../../../helpers/pump_app.dart';

// ---------------------------------------------------------------------------
// Fakes & mocks
// ---------------------------------------------------------------------------

class _MockSanctionRepository extends Mock implements SanctionRepository {}

class _MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

class _NoopAnalytics extends SanctionAnalytics {
  _NoopAnalytics() : super(analytics: _MockFirebaseAnalytics());
  int appealStartedCount = 0;

  @override
  void appealStarted({required String sanctionId}) {
    appealStartedCount++;
  }

  @override
  void suspensionGateShown({
    required String sanctionId,
    required SanctionType type,
  }) {}

  @override
  void appealSubmitted({required String sanctionId, required int bodyLength}) {}

  @override
  void appealFailed({required String sanctionId, required String errorCode}) {}
}

SanctionEntity _sanction({bool permanent = false}) => SanctionEntity(
  id: 'appeal-sanction-001',
  userId: 'user-1',
  type: SanctionType.suspension,
  reason: 'Rule violation',
  createdAt: DateTime.now().subtract(const Duration(days: 1)),
  expiresAt: permanent ? null : DateTime.now().add(const Duration(days: 6)),
);

Future<void> _pumpAppeal(
  WidgetTester tester, {
  required SanctionEntity sanction,
  _NoopAnalytics? analytics,
}) async {
  final noop = analytics ?? _NoopAnalytics();
  SharedPreferences.setMockInitialValues({});

  await pumpTestScreenWithProviders(
    tester,
    AppealScreen(sanction: sanction),
    overrides: [
      sanctionAnalyticsProvider.overrideWithValue(noop),
      currentUserProvider.overrideWithValue(null),
      sanctionRepositoryProvider.overrideWithValue(_MockSanctionRepository()),
    ],
  );
}

void main() {
  group('AppealScreen — renders correctly', () {
    testWidgets('renders sanction summary card', (tester) async {
      await _pumpAppeal(tester, sanction: _sanction());

      expect(find.byType(AppealSanctionSummaryCard), findsOneWidget);
    });

    testWidgets('renders appeal text field', (tester) async {
      await _pumpAppeal(tester, sanction: _sanction());

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('renders char counter starting at 0', (tester) async {
      await _pumpAppeal(tester, sanction: _sanction());

      expect(find.text('0 / 1000'), findsOneWidget);
    });

    testWidgets('submit button disabled when text is empty', (tester) async {
      await _pumpAppeal(tester, sanction: _sanction());

      final submitFinder = find.textContaining('sanction.screen.appeal_submit');
      expect(submitFinder, findsOneWidget);
      // DeelButton passes null onPressed when disabled.
      final button = tester.widget<ElevatedButton>(
        find
            .ancestor(of: submitFinder, matching: find.byType(ElevatedButton))
            .first,
      );
      expect(button.onPressed, isNull);
    });
  });

  group('AppealScreen — char counter updates', () {
    testWidgets('counter increments as text is entered', (tester) async {
      await _pumpAppeal(tester, sanction: _sanction());

      await tester.enterText(find.byType(TextField), 'hello world');
      await tester.pump();

      expect(find.text('11 / 1000'), findsOneWidget);
    });

    testWidgets('counter shows 0 for empty field', (tester) async {
      await _pumpAppeal(tester, sanction: _sanction());

      await tester.enterText(find.byType(TextField), '');
      await tester.pump();

      expect(find.text('0 / 1000'), findsOneWidget);
    });
  });

  group('AppealScreen — submit button enabled/disabled', () {
    testWidgets('submit disabled with 9 chars', (tester) async {
      await _pumpAppeal(tester, sanction: _sanction());

      await tester.enterText(find.byType(TextField), '123456789');
      await tester.pump();

      final submitFinder = find.textContaining('sanction.screen.appeal_submit');
      final button = tester.widget<ElevatedButton>(
        find
            .ancestor(of: submitFinder, matching: find.byType(ElevatedButton))
            .first,
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('submit enabled with 10+ chars', (tester) async {
      await _pumpAppeal(tester, sanction: _sanction());

      await tester.enterText(find.byType(TextField), '1234567890');
      await tester.pump();

      final submitFinder = find.textContaining('sanction.screen.appeal_submit');
      final button = tester.widget<ElevatedButton>(
        find
            .ancestor(of: submitFinder, matching: find.byType(ElevatedButton))
            .first,
      );
      expect(button.onPressed, isNotNull);
    });
  });

  group('AppealScreen — analytics', () {
    testWidgets('appealStarted fires on first frame', (tester) async {
      final analytics = _NoopAnalytics();
      await _pumpAppeal(tester, sanction: _sanction(), analytics: analytics);

      // addPostFrameCallback fires after first pump.
      await tester.pump();

      expect(analytics.appealStartedCount, 1);
    });
  });

  group('AppealScreen — draft pre-fill', () {
    testWidgets('pre-fills text from SharedPreferences draft', (tester) async {
      SharedPreferences.setMockInitialValues({
        'appeal_draft_appeal-sanction-001': 'My pre-saved draft text here.',
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sanctionAnalyticsProvider.overrideWithValue(_NoopAnalytics()),
            currentUserProvider.overrideWithValue(null),
            sanctionRepositoryProvider.overrideWithValue(
              _MockSanctionRepository(),
            ),
          ],
          child: MaterialApp(
            home: AppealScreen(
              sanction: SanctionEntity(
                id: 'appeal-sanction-001',
                userId: 'user-1',
                type: SanctionType.suspension,
                reason: 'Rule violation',
                createdAt: DateTime.fromMillisecondsSinceEpoch(0),
              ),
            ),
          ),
        ),
      );
      // Pump through post-frame callback and draft load.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('My pre-saved draft text here.'), findsOneWidget);
    });
  });
}
