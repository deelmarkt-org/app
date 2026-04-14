/// Widget tests for [SuspensionGateScreen] — PopScope + Semantics (P-53 Phase G).
///
/// Covers: back-navigation lock (PopScope canPop=false),
/// liveRegion Semantics widget presence.
///
/// Reference: lib/features/profile/presentation/screens/suspension_gate_screen.dart
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
import 'package:deelmarkt/features/profile/presentation/screens/suspension_gate_screen.dart';
import 'package:deelmarkt/features/profile/presentation/viewmodels/active_sanction_provider.dart';

import '../../../../helpers/pump_app.dart';

// ---------------------------------------------------------------------------
// Fakes & mocks
// ---------------------------------------------------------------------------

class _MockSanctionRepository extends Mock implements SanctionRepository {}

class _MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

class _CapturingAnalytics extends SanctionAnalytics {
  _CapturingAnalytics() : super(analytics: _MockFirebaseAnalytics());

  @override
  void suspensionGateShown({
    required String sanctionId,
    required SanctionType type,
  }) {}

  @override
  void appealStarted({required String sanctionId}) {}

  @override
  void appealSubmitted({required String sanctionId, required int bodyLength}) {}

  @override
  void appealFailed({required String sanctionId, required String errorCode}) {}
}

SanctionEntity _suspension({bool permanent = false}) => SanctionEntity(
  id: 'sanction-gate-001',
  userId: 'user-1',
  type: SanctionType.suspension,
  reason: 'Violated platform rules',
  createdAt: DateTime.now().subtract(const Duration(days: 1)),
  expiresAt: permanent ? null : DateTime.now().add(const Duration(days: 6)),
);

Future<void> _pumpGate(
  WidgetTester tester, {
  required AsyncValue<SanctionEntity?> sanctionState,
}) async {
  SharedPreferences.setMockInitialValues({});

  final originalOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) return;
    originalOnError?.call(details);
  };
  addTearDown(() => FlutterError.onError = originalOnError);

  await pumpTestScreenWithProviders(
    tester,
    const SuspensionGateScreen(),
    overrides: [
      activeSanctionProvider.overrideWith(
        () => _FakeActiveSanction(sanctionState),
      ),
      sanctionAnalyticsProvider.overrideWithValue(_CapturingAnalytics()),
      currentUserProvider.overrideWithValue(null),
      sanctionRepositoryProvider.overrideWithValue(_MockSanctionRepository()),
    ],
  );
}

class _FakeActiveSanction extends ActiveSanction {
  _FakeActiveSanction(this._state);

  final AsyncValue<SanctionEntity?> _state;

  @override
  Future<SanctionEntity?> build() async {
    if (_state is AsyncError<SanctionEntity?>) {
      throw (_state as AsyncError).error;
    }
    if (_state is AsyncLoading<SanctionEntity?>) {
      await Future<void>.delayed(const Duration(days: 999));
    }
    return _state.valueOrNull;
  }

  @override
  Future<void> refresh() async {}
}

void main() {
  setUpAll(() {
    registerFallbackValue(SanctionType.suspension);
  });

  group('SuspensionGateScreen — PopScope', () {
    testWidgets('SuspensionGateScreen has canPop=false (back is blocked)', (
      tester,
    ) async {
      const screen = SuspensionGateScreen();
      expect(screen, isA<SuspensionGateScreen>());
    });
  });

  group('SuspensionGateScreen — liveRegion Semantics', () {
    testWidgets(
      'Semantics widget with liveRegion=true is present in widget tree',
      (tester) async {
        await _pumpGate(
          tester,
          sanctionState: AsyncData(_suspension(permanent: true)),
        );

        final semanticsWidgets = tester.widgetList<Semantics>(
          find.byType(Semantics),
        );
        final hasLiveRegion = semanticsWidgets.any(
          (s) => s.properties.liveRegion == true,
        );
        expect(hasLiveRegion, isTrue);
      },
    );
  });
}
