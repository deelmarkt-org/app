import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/features/admin/domain/entities/activity_item_entity.dart';
import 'package:deelmarkt/features/admin/domain/entities/admin_stats_entity.dart';
import 'package:deelmarkt/features/admin/presentation/admin_dashboard_notifier.dart';
import 'package:deelmarkt/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:deelmarkt/features/admin/presentation/widgets/admin_empty_state.dart';
import 'package:deelmarkt/features/admin/presentation/widgets/admin_loading_skeleton.dart';
import 'package:deelmarkt/widgets/feedback/error_state.dart';

// ── Stubs ────────────────────────────────────────────────────────────────────

/// Stays in loading state forever — use tester.pump() (not pumpAndSettle).
class _LoadingNotifier extends AdminDashboardNotifier {
  @override
  Future<AdminDashboardState> build() =>
      Completer<AdminDashboardState>().future;

  @override
  Future<void> refresh() async {}
}

/// Always throws — triggers the error branch.
class _ErrorNotifier extends AdminDashboardNotifier {
  @override
  Future<AdminDashboardState> build() async => throw Exception('network error');

  @override
  Future<void> refresh() async {}
}

/// Returns fixed data synchronously.
class _DataNotifier extends AdminDashboardNotifier {
  _DataNotifier(this._data);

  final AdminDashboardState _data;

  @override
  Future<AdminDashboardState> build() async => _data;

  @override
  Future<void> refresh() async {}
}

// ── Test data ────────────────────────────────────────────────────────────────

const _emptyStats = AdminStatsEntity(
  openDisputes: 0,
  dsaNoticesWithin24h: 0,
  activeListings: 0,
  escrowAmountCents: 0,
  flaggedListings: 0,
  reportedUsers: 0,
  approvedCount: 0,
);

const _nonEmptyStats = AdminStatsEntity(
  openDisputes: 3,
  dsaNoticesWithin24h: 1,
  activeListings: 120,
  escrowAmountCents: 1245000,
  flaggedListings: 5,
  reportedUsers: 2,
  approvedCount: 10,
);

final _sampleActivity = <ActivityItemEntity>[
  ActivityItemEntity(
    id: 'act-1',
    type: ActivityItemType.listingRemoved,
    title: 'Listing removed',
    subtitle: 'Policy violation',
    timestamp: DateTime(2026, 4, 10),
  ),
];

// ── Helpers ──────────────────────────────────────────────────────────────────

Future<void> _pump(
  WidgetTester tester,
  AdminDashboardNotifier notifier, {
  bool settle = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [adminDashboardNotifierProvider.overrideWith(() => notifier)],
      child: MaterialApp(
        theme: DeelmarktTheme.light,
        home: Builder(
          builder:
              (ctx) => MediaQuery(
                data: MediaQuery.of(ctx).copyWith(disableAnimations: true),
                child: const AdminDashboardScreen(),
              ),
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

void suppressOverflowErrors() {
  final handler = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) return;
    handler?.call(details);
  };
  addTearDown(() => FlutterError.onError = handler);
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('AdminDashboardScreen', () {
    testWidgets('shows loading skeleton while loading', (tester) async {
      await _pump(tester, _LoadingNotifier(), settle: false);

      expect(find.byType(AdminLoadingSkeleton), findsOneWidget);
    });

    testWidgets('shows error state with retry button on failure', (
      tester,
    ) async {
      await _pump(tester, _ErrorNotifier());

      expect(find.byType(ErrorState), findsOneWidget);
    });

    testWidgets('shows empty state when all stats are zero', (tester) async {
      await _pump(
        tester,
        _DataNotifier(
          const AdminDashboardState(stats: _emptyStats, activity: []),
        ),
      );

      expect(find.byType(AdminEmptyState), findsOneWidget);
    });

    testWidgets('renders 4 stat card labels when data is non-empty', (
      tester,
    ) async {
      suppressOverflowErrors();
      await _pump(
        tester,
        _DataNotifier(
          AdminDashboardState(stats: _nonEmptyStats, activity: _sampleActivity),
        ),
      );

      expect(find.text('admin.stats.openDisputes'), findsOneWidget);
      expect(find.text('admin.stats.dsaNotices'), findsOneWidget);
      expect(find.text('admin.stats.activeListings'), findsOneWidget);
      expect(find.text('admin.stats.escrow'), findsOneWidget);
    });

    testWidgets('formats escrow amount with nl_NL thousands separator', (
      tester,
    ) async {
      suppressOverflowErrors();
      await _pump(
        tester,
        _DataNotifier(
          const AdminDashboardState(stats: _nonEmptyStats, activity: []),
        ),
      );

      // €12.450 — nl_NL: period as thousands separator, no decimal places
      expect(find.text('\u20AC12.450'), findsOneWidget);
    });
  });
}
