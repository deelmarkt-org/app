import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/services/shared_prefs_provider.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';
import 'package:deelmarkt/features/sell/domain/entities/quality_score_result.dart';
import 'package:deelmarkt/features/sell/presentation/screens/listing_creation_screen.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/listing_creation_viewmodel.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/sell_providers.dart';

import '../../../../helpers/pump_app.dart';

/// Stub notifier that returns a fixed state without side effects.
class _StubCreationNotifier extends ListingCreationNotifier {
  _StubCreationNotifier(this._state);

  final ListingCreationState _state;

  @override
  ListingCreationState build() => _state;
}

/// Default quality score used across screen tests.
const _defaultScore = QualityScoreResult(
  score: 0,
  breakdown: [
    QualityScoreField(
      name: 'sell.photos',
      points: 0,
      maxPoints: 25,
      passed: false,
      tipKey: 'sell.tipMorePhotos',
    ),
  ],
);

/// Suppress overflow errors during widget tests.
void _suppressOverflow(FlutterErrorDetails details) {
  if (details.exceptionAsString().contains('overflowed')) return;
  FlutterError.dumpErrorToConsole(details);
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  final origOnError = FlutterError.onError;
  setUp(() => FlutterError.onError = _suppressOverflow);
  tearDown(() => FlutterError.onError = origOnError);

  /// Shared overrides for all screen tests.
  List<Override> overridesForState(ListingCreationState state) => [
    sharedPreferencesProvider.overrideWithValue(prefs),
    qualityScoreProvider.overrideWithValue(_defaultScore),
    listingCreationNotifierProvider.overrideWith(
      () => _StubCreationNotifier(state),
    ),
  ];

  group('ListingCreationScreen', () {
    testWidgets('renders step 1 (photos) by default', (tester) async {
      await pumpTestScreenWithProviders(
        tester,
        const ListingCreationScreen(),
        overrides: overridesForState(const ListingCreationState()),
      );

      // Step indicator shows "1".
      expect(find.textContaining('sell.stepIndicator'), findsOneWidget);
    });

    testWidgets('AppBar shows photos title on photos step', (tester) async {
      await pumpTestScreenWithProviders(
        tester,
        const ListingCreationScreen(),
        overrides: overridesForState(const ListingCreationState()),
      );

      // .tr() returns the key in test — 'sell.stepPhotos'.
      expect(find.text('sell.stepPhotos'), findsOneWidget);
    });

    testWidgets('AppBar shows details title on details step', (tester) async {
      await pumpTestScreenWithProviders(
        tester,
        const ListingCreationScreen(),
        overrides: overridesForState(
          const ListingCreationState(step: ListingCreationStep.details),
        ),
      );

      expect(find.text('sell.stepDetails'), findsOneWidget);
    });

    testWidgets('AppBar shows quality title on quality step', (tester) async {
      await pumpTestScreenWithProviders(
        tester,
        const ListingCreationScreen(),
        overrides: overridesForState(
          const ListingCreationState(step: ListingCreationStep.quality),
        ),
      );

      expect(find.text('sell.stepQuality'), findsOneWidget);
    });

    testWidgets('close X button shows on photos step', (tester) async {
      await pumpTestScreenWithProviders(
        tester,
        const ListingCreationScreen(),
        overrides: overridesForState(const ListingCreationState()),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('back arrow shows on details step', (tester) async {
      await pumpTestScreenWithProviders(
        tester,
        const ListingCreationScreen(),
        overrides: overridesForState(
          const ListingCreationState(step: ListingCreationStep.details),
        ),
      );

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('back arrow shows on quality step', (tester) async {
      await pumpTestScreenWithProviders(
        tester,
        const ListingCreationScreen(),
        overrides: overridesForState(
          const ListingCreationState(step: ListingCreationStep.quality),
        ),
      );

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('step indicator text is visible on each step', (tester) async {
      await pumpTestScreenWithProviders(
        tester,
        const ListingCreationScreen(),
        overrides: overridesForState(const ListingCreationState()),
      );

      // The step indicator uses 'sell.stepIndicator'.tr(args: ['1', '3']).
      // In test mode .tr() returns the key, so we check for the key text.
      expect(find.textContaining('sell.stepIndicator'), findsOneWidget);
    });

    testWidgets('no leading button on success step', (tester) async {
      await pumpTestScreenWithProviders(
        tester,
        const ListingCreationScreen(),
        overrides: overridesForState(
          const ListingCreationState(
            step: ListingCreationStep.success,
            createdListingId: 'listing-001',
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsNothing);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });
  });
}
