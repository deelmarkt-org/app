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
import 'package:deelmarkt/features/profile/domain/exceptions/sanction_exceptions.dart';
import 'package:deelmarkt/features/profile/domain/repositories/sanction_repository.dart';
import 'package:deelmarkt/features/profile/presentation/screens/appeal_screen.dart';
import 'package:deelmarkt/features/profile/presentation/viewmodels/appeal_notifier.dart';
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

class _FakeAppealNotifier extends AppealNotifier {
  _FakeAppealNotifier({this.throwOn});

  /// If non-null, [submit] throws this exception instead of calling the repo.
  final SanctionException? throwOn;

  @override
  AsyncValue<void> build() => const AsyncData(null);

  @override
  Future<void> submit({
    required String sanctionId,
    required String body,
  }) async {
    if (body.trim().length < 10 || body.length > 1000) {
      throw ArgumentError('invalid appeal body length');
    }
    if (throwOn != null) {
      state = AsyncError(throwOn!, StackTrace.empty);
      return;
    }
    state = const AsyncLoading();
    await Future<void>.microtask(() {});
    state = const AsyncData(null);
  }

  @override
  Future<void> saveDraft({
    required String sanctionId,
    required String body,
  }) async {}

  @override
  Future<String?> loadDraft({required String sanctionId}) async => null;

  @override
  Future<void> clearDraft({required String sanctionId}) async {}
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
  AppealNotifier Function()? notifierFactory,
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
      if (notifierFactory != null)
        appealNotifierProvider.overrideWith(notifierFactory),
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

  group('AppealScreen — submit error snackbar', () {
    testWidgets('shows snackbar with l10n key on AppealWindowExpired', (
      tester,
    ) async {
      await _pumpAppeal(
        tester,
        sanction: _sanction(),
        notifierFactory:
            () => _FakeAppealNotifier(throwOn: const AppealWindowExpired()),
      );

      await tester.enterText(
        find.byType(TextField),
        'This is a valid appeal body.',
      );
      await tester.pump();

      await tester.tap(find.textContaining('sanction.screen.appeal_submit'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('sanction.screen.appeal_window_closed'),
        findsOneWidget,
      );
    });
  });

  group('AppealScreen — dirty-back discard dialog', () {
    testWidgets('shows discard dialog when back is pressed with dirty text', (
      tester,
    ) async {
      await _pumpAppeal(tester, sanction: _sanction());

      await tester.enterText(
        find.byType(TextField),
        'some non-empty text here',
      );
      await tester.pump();

      // Simulate back button via AppBar leading icon.
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('sanction.screen.discard_title'),
        findsOneWidget,
      );
      expect(
        find.textContaining('sanction.screen.discard_body'),
        findsOneWidget,
      );
      expect(
        find.textContaining('sanction.screen.discard_confirm'),
        findsOneWidget,
      );
      expect(
        find.textContaining('sanction.screen.discard_cancel'),
        findsOneWidget,
      );
    });

    testWidgets('dismisses discard dialog on cancel (stays on screen)', (
      tester,
    ) async {
      await _pumpAppeal(tester, sanction: _sanction());

      await tester.enterText(
        find.byType(TextField),
        'some non-empty text here',
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('sanction.screen.discard_cancel'));
      await tester.pumpAndSettle();

      // Dialog gone; appeal screen still rendered.
      expect(
        find.textContaining('sanction.screen.discard_title'),
        findsNothing,
      );
      expect(find.byType(AppealScreen), findsOneWidget);
    });
  });
}
