import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/home/presentation/home_screen.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_listing_card.dart';

void main() {
  group('HomeScreen', () {
    // Smoke test for the screen wrapper — verifies the build() switch
    // on the HomeNotifier AsyncValue actually mounts the loading view
    // without throwing. The notifier's data/error/refresh paths are
    // exercised in detail by home_notifier_test.dart, and HomeDataView
    // has its own widget tests, so this file only needs to prove the
    // top-level wiring compiles and renders.
    //
    // We don't drive the test past the loading frame here because the
    // mock repos use Future.delayed and ScrollView animations leave
    // pending timers that pumpAndSettle would (correctly) reject.

    testWidgets('renders the loading skeletons during the initial frame', (
      tester,
    ) async {
      // runAsync uses real wall-clock time so the mock repos'
      // Future.delayed timers can complete before the test tearDown
      // verifies there are no pending timers.
      await tester.runAsync(() async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [useMockDataProvider.overrideWithValue(true)],
            child: MaterialApp(
              theme: DeelmarktTheme.light,
              home: const HomeScreen(),
            ),
          ),
        );
        await tester.pump(); // First frame, before any mock future resolves.
        expect(find.byType(SkeletonListingCard), findsWidgets);
        // Drain pending mock futures so the test binding's
        // !timersPending invariant is satisfied at tearDown.
        await Future<void>.delayed(const Duration(milliseconds: 350));
      });
    });
  });
}
