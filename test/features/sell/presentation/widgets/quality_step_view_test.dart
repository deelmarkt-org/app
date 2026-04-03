import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/services/shared_prefs_provider.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';
import 'package:deelmarkt/features/sell/domain/entities/quality_score_result.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/listing_creation_viewmodel.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/sell_providers.dart';
import 'package:deelmarkt/features/sell/presentation/widgets/quality_step/quality_score_ring.dart';
import 'package:deelmarkt/features/sell/presentation/widgets/quality_step/quality_step_view.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

import '../../../../helpers/pump_app.dart';

/// Stub notifier that returns a fixed state.
class _StubListingCreationNotifier extends ListingCreationNotifier {
  _StubListingCreationNotifier(this._state);

  final ListingCreationState _state;

  @override
  ListingCreationState build() => _state;
}

const _highScoreResult = QualityScoreResult(
  score: 78,
  breakdown: [
    QualityScoreField(
      name: 'sell.photos',
      points: 25,
      maxPoints: 25,
      passed: true,
    ),
    QualityScoreField(
      name: 'sell.title',
      points: 15,
      maxPoints: 15,
      passed: true,
    ),
    QualityScoreField(
      name: 'sell.description',
      points: 20,
      maxPoints: 20,
      passed: true,
    ),
    QualityScoreField(
      name: 'sell.price',
      points: 15,
      maxPoints: 15,
      passed: true,
    ),
    QualityScoreField(
      name: 'sell.category',
      points: 0,
      maxPoints: 15,
      passed: false,
      tipKey: 'sell.categoryTip',
    ),
    QualityScoreField(
      name: 'sell.condition',
      points: 0,
      maxPoints: 10,
      passed: false,
      tipKey: 'sell.conditionTip',
    ),
  ],
);

const _lowScoreResult = QualityScoreResult(
  score: 15,
  breakdown: [
    QualityScoreField(
      name: 'sell.photos',
      points: 0,
      maxPoints: 25,
      passed: false,
      tipKey: 'sell.tipMorePhotos',
    ),
    QualityScoreField(
      name: 'sell.title',
      points: 15,
      maxPoints: 15,
      passed: true,
    ),
  ],
);

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  /// Suppress overflow errors in constrained test viewports.
  final origOnError = FlutterError.onError;
  setUp(
    () =>
        FlutterError.onError = (details) {
          if (details.exceptionAsString().contains('overflowed')) return;
          FlutterError.dumpErrorToConsole(details);
        },
  );
  tearDown(() => FlutterError.onError = origOnError);

  group('QualityStepView', () {
    testWidgets('shows score ring', (tester) async {
      await pumpTestScreenWithProviders(
        tester,
        const Scaffold(body: QualityStepView()),
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          qualityScoreProvider.overrideWithValue(_highScoreResult),
          listingCreationNotifierProvider.overrideWith(
            () => _StubListingCreationNotifier(
              const ListingCreationState(step: ListingCreationStep.quality),
            ),
          ),
        ],
      );

      expect(find.byType(QualityScoreRing), findsOneWidget);
    });

    testWidgets('shows breakdown rows for each field', (tester) async {
      await pumpTestScreenWithProviders(
        tester,
        const Scaffold(body: QualityStepView()),
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          qualityScoreProvider.overrideWithValue(_highScoreResult),
          listingCreationNotifierProvider.overrideWith(
            () => _StubListingCreationNotifier(
              const ListingCreationState(step: ListingCreationStep.quality),
            ),
          ),
        ],
      );

      // Verify breakdown rows show points text.
      expect(find.text('25/25'), findsOneWidget);
      expect(find.text('15/15'), findsWidgets);
      expect(find.text('0/15'), findsOneWidget);
      expect(find.text('0/10'), findsOneWidget);
    });

    testWidgets('publish button disabled when score < 40', (tester) async {
      await pumpTestScreenWithProviders(
        tester,
        const Scaffold(body: QualityStepView()),
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          qualityScoreProvider.overrideWithValue(_lowScoreResult),
          listingCreationNotifierProvider.overrideWith(
            () => _StubListingCreationNotifier(
              const ListingCreationState(step: ListingCreationStep.quality),
            ),
          ),
        ],
      );

      // Find the publish DeelButton — its onPressed should be null.
      final publishButton =
          tester.widgetList<DeelButton>(find.byType(DeelButton)).first;
      expect(publishButton.onPressed, isNull);
    });

    testWidgets('publish button enabled when score >= 40', (tester) async {
      await pumpTestScreenWithProviders(
        tester,
        const Scaffold(body: QualityStepView()),
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          qualityScoreProvider.overrideWithValue(_highScoreResult),
          listingCreationNotifierProvider.overrideWith(
            () => _StubListingCreationNotifier(
              const ListingCreationState(step: ListingCreationStep.quality),
            ),
          ),
        ],
      );

      final publishButton =
          tester.widgetList<DeelButton>(find.byType(DeelButton)).first;
      expect(publishButton.onPressed, isNotNull);
    });

    testWidgets('draft button is always visible', (tester) async {
      await pumpTestScreenWithProviders(
        tester,
        const Scaffold(body: QualityStepView()),
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          qualityScoreProvider.overrideWithValue(_lowScoreResult),
          listingCreationNotifierProvider.overrideWith(
            () => _StubListingCreationNotifier(
              const ListingCreationState(step: ListingCreationStep.quality),
            ),
          ),
        ],
      );

      // There should be two DeelButton widgets: publish + draft.
      expect(find.byType(DeelButton), findsNWidgets(2));

      // The second button is the draft button (ghost variant).
      final draftButton =
          tester.widgetList<DeelButton>(find.byType(DeelButton)).last;
      expect(draftButton.variant, equals(DeelButtonVariant.ghost));
    });
  });
}
