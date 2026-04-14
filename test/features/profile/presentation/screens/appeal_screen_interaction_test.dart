/// Widget tests for [AppealScreen] — interaction flows (P-53 Phase G).
///
/// Covers: submit error snackbar, dirty-back discard dialog.
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

import '../../../../helpers/pump_app.dart';

// ---------------------------------------------------------------------------
// Fakes & mocks
// ---------------------------------------------------------------------------

class _MockSanctionRepository extends Mock implements SanctionRepository {}

class _MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

class _NoopAnalytics extends SanctionAnalytics {
  _NoopAnalytics() : super(analytics: _MockFirebaseAnalytics());

  @override
  void appealStarted({required String sanctionId}) {}

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

SanctionEntity _sanction() => SanctionEntity(
  id: 'appeal-sanction-001',
  userId: 'user-1',
  type: SanctionType.suspension,
  reason: 'Rule violation',
  createdAt: DateTime.now().subtract(const Duration(days: 1)),
  expiresAt: DateTime.now().add(const Duration(days: 6)),
);

Future<void> _pumpAppeal(
  WidgetTester tester, {
  required SanctionEntity sanction,
  AppealNotifier Function()? notifierFactory,
}) async {
  SharedPreferences.setMockInitialValues({});

  await pumpTestScreenWithProviders(
    tester,
    AppealScreen(sanction: sanction),
    overrides: [
      sanctionAnalyticsProvider.overrideWithValue(_NoopAnalytics()),
      currentUserProvider.overrideWithValue(null),
      sanctionRepositoryProvider.overrideWithValue(_MockSanctionRepository()),
      if (notifierFactory != null)
        appealNotifierProvider.overrideWith(notifierFactory),
    ],
  );
}

void main() {
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

      expect(
        find.textContaining('sanction.screen.discard_title'),
        findsNothing,
      );
      expect(find.byType(AppealScreen), findsOneWidget);
    });
  });
}
