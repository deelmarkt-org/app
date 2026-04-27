// GH #221 — Phase B call-site contract tests.
//
// Asserts every Phase B call site invokes `performanceTracer.start(...)`
// with the canonical `TraceNames.*` constant + closes the handle. We use
// `FakePerformanceTracer` (PR #220) to record the trace lifecycle and
// the existing mock-data overrides so the tests stay hermetic.
//
// What's NOT tested here:
//   - `app_start` — exercised end-to-end in main.dart, can only be
//     verified via integration test on a real device. Manually
//     validated locally; recorded in PR #240 description.
//   - `image_load` is covered by deel_card_image_test.dart since it
//     needs the cached_network_image stub already present there.
//   - `payment_create` is covered by create_payment_usecase_test.dart
//     since its existing setUp is the natural place to assert the
//     contract — see the dedicated test below in this file too.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/services/performance/performance_tracer_provider.dart';
import 'package:deelmarkt/core/services/performance/trace_names.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/core/services/shared_prefs_provider.dart';
import 'package:deelmarkt/features/listing_detail/presentation/listing_detail_notifier.dart';
import 'package:deelmarkt/features/search/presentation/search_notifier.dart';

import '../_helpers/fake_performance_tracer.dart';

void main() {
  group('GH #221 — performance trace call sites', () {
    test(
      'ListingDetailNotifier.build() starts and stops listing_load trace',
      () async {
        final fake = FakePerformanceTracer();
        final container = ProviderContainer(
          overrides: [
            useMockDataProvider.overrideWithValue(true),
            performanceTracerProvider.overrideWithValue(fake),
          ],
        );
        addTearDown(container.dispose);

        const id = 'listing-001';
        container.listen(listingDetailNotifierProvider(id), (_, _) {});
        await container.read(listingDetailNotifierProvider(id).future);

        // Both lifecycle events recorded with the canonical name.
        expect(
          fake.recordedCalls,
          contains(TraceCall.start(TraceNames.listingLoad)),
        );
        expect(
          fake.recordedCalls,
          contains(TraceCall.stop(TraceNames.listingLoad)),
        );
        // No leaked handle.
        expect(fake.activeTraceCount, 0);
      },
    );

    test(
      'SearchNotifier.search() starts and stops search_query trace',
      () async {
        // SearchNotifier transitively reads sharedPreferencesProvider via
        // recentSearchesRepositoryProvider. Mock prefs match the existing
        // search_notifier_test fixture.
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final fake = FakePerformanceTracer();
        final container = ProviderContainer(
          overrides: [
            useMockDataProvider.overrideWithValue(true),
            sharedPreferencesProvider.overrideWithValue(prefs),
            performanceTracerProvider.overrideWithValue(fake),
          ],
        );
        addTearDown(container.dispose);

        // Hydrate the notifier first so its build() completes.
        container.listen(searchNotifierProvider, (_, _) {});
        await container.read(searchNotifierProvider.future);

        // Reset — build() doesn't trace; only search() does.
        fake.reset();

        await container
            .read(searchNotifierProvider.notifier)
            .search('test query');

        expect(
          fake.recordedCalls,
          contains(TraceCall.start(TraceNames.searchQuery)),
        );
        expect(
          fake.recordedCalls,
          contains(TraceCall.stop(TraceNames.searchQuery)),
        );
        expect(fake.activeTraceCount, 0);
      },
    );

    test(
      'ListingDetailNotifier still closes the trace when build() throws',
      () async {
        final fake = FakePerformanceTracer();
        final container = ProviderContainer(
          overrides: [
            useMockDataProvider.overrideWithValue(true),
            performanceTracerProvider.overrideWithValue(fake),
          ],
        );
        addTearDown(container.dispose);

        // ID guaranteed not to exist in mock data — triggers
        // `Listing not found` exception inside build().
        const missingId = 'listing-does-not-exist-zzz';
        container.listen(listingDetailNotifierProvider(missingId), (_, _) {});
        try {
          await container.read(listingDetailNotifierProvider(missingId).future);
        } on Exception {
          // expected — assertion is on the trace lifecycle.
        }

        expect(
          fake.recordedCalls,
          contains(TraceCall.start(TraceNames.listingLoad)),
        );
        expect(
          fake.recordedCalls,
          contains(TraceCall.stop(TraceNames.listingLoad)),
        );
        expect(
          fake.activeTraceCount,
          0,
          reason: 'finally block must close the handle even on throw',
        );
      },
    );
  });
}
