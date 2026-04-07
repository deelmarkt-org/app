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

  List<Override> overridesForState(ListingCreationState state) => [
    sharedPreferencesProvider.overrideWithValue(prefs),
    qualityScoreProvider.overrideWithValue(_defaultScore),
    listingCreationNotifierProvider.overrideWith(
      () => _StubCreationNotifier(state),
    ),
  ];

  group('ListingCreationScreen -- discard dialog', () {
    testWidgets('discard dialog appears when back pressed with unsaved data', (
      tester,
    ) async {
      await pumpTestScreenWithProviders(
        tester,
        const ListingCreationScreen(),
        overrides: overridesForState(
          const ListingCreationState(imageFiles: ['/mock/photo.jpg']),
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('sell.discardTitle'), findsOneWidget);
      expect(find.text('sell.discardMessage'), findsOneWidget);
      expect(find.text('sell.keepEditing'), findsOneWidget);
      expect(find.text('sell.discard'), findsOneWidget);
    });

    testWidgets('keep editing button closes discard dialog', (tester) async {
      await pumpTestScreenWithProviders(
        tester,
        const ListingCreationScreen(),
        overrides: overridesForState(
          const ListingCreationState(imageFiles: ['/mock/photo.jpg']),
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      await tester.tap(find.text('sell.keepEditing'));
      await tester.pumpAndSettle();

      expect(find.text('sell.discardTitle'), findsNothing);
      expect(find.text('sell.stepPhotos'), findsOneWidget);
    });

    testWidgets('hasUnsavedData true triggers discard dialog on close', (
      tester,
    ) async {
      await pumpTestScreenWithProviders(
        tester,
        const ListingCreationScreen(),
        overrides: overridesForState(
          const ListingCreationState(title: 'Unsaved'),
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('sell.discardTitle'), findsOneWidget);
    });
  });

  group('ListingCreationScreen -- responsive layout', () {
    testWidgets('live preview shows on expanded width', (tester) async {
      tester.view.physicalSize = const Size(2400, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await pumpTestScreenWithProviders(
        tester,
        const ListingCreationScreen(),
        overrides: overridesForState(
          const ListingCreationState(title: 'Preview Test', priceInCents: 1500),
        ),
      );

      expect(find.text('sell.livePreview'), findsOneWidget);
    });

    testWidgets('live preview hidden on compact width', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await pumpTestScreenWithProviders(
        tester,
        const ListingCreationScreen(),
        overrides: overridesForState(const ListingCreationState()),
      );

      expect(find.text('sell.livePreview'), findsNothing);
    });
  });
}
