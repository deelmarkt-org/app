import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
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

    testWidgets('publishing step shows CircularProgressIndicator', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: overridesForState(
            const ListingCreationState(step: ListingCreationStep.publishing),
          ),
          child: MaterialApp(
            theme: DeelmarktTheme.light,
            home: const ListingCreationScreen(),
          ),
        ),
      );
      // Use pump() instead of pumpAndSettle() — CircularProgressIndicator
      // never settles because it animates continuously.
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('step indicator text visible on details step', (tester) async {
      await pumpTestScreenWithProviders(
        tester,
        const ListingCreationScreen(),
        overrides: overridesForState(
          const ListingCreationState(step: ListingCreationStep.details),
        ),
      );

      expect(find.textContaining('sell.stepIndicator'), findsOneWidget);
    });

    testWidgets('step indicator text visible on quality step', (tester) async {
      await pumpTestScreenWithProviders(
        tester,
        const ListingCreationScreen(),
        overrides: overridesForState(
          const ListingCreationState(step: ListingCreationStep.quality),
        ),
      );

      expect(find.textContaining('sell.stepIndicator'), findsOneWidget);
    });

    testWidgets('AppBar title shows publishing label on publishing step', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: overridesForState(
            const ListingCreationState(step: ListingCreationStep.publishing),
          ),
          child: MaterialApp(
            theme: DeelmarktTheme.light,
            home: const ListingCreationScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('sell.stepPublishing'), findsOneWidget);
    });

    testWidgets('AppBar title shows success label on success step', (
      tester,
    ) async {
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

      expect(find.text('sell.stepSuccess'), findsOneWidget);
    });

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

      // Tap the close button when there is unsaved data.
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Discard dialog should appear.
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

      // Open discard dialog.
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Tap keep editing.
      await tester.tap(find.text('sell.keepEditing'));
      await tester.pumpAndSettle();

      // Dialog dismissed, screen still visible.
      expect(find.text('sell.discardTitle'), findsNothing);
      expect(find.text('sell.stepPhotos'), findsOneWidget);
    });

    testWidgets('close button visible with no unsaved data', (tester) async {
      await pumpTestScreenWithProviders(
        tester,
        const ListingCreationScreen(),
        overrides: overridesForState(const ListingCreationState()),
      );

      // Close button is present when there is no unsaved data.
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('Scaffold body uses SafeArea', (tester) async {
      await pumpTestScreenWithProviders(
        tester,
        const ListingCreationScreen(),
        overrides: overridesForState(const ListingCreationState()),
      );

      expect(find.byType(SafeArea), findsAtLeast(1));
    });

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

      // Live preview shows the preview label on expanded screens.
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

      // Live preview should not be visible on compact width.
      expect(find.text('sell.livePreview'), findsNothing);
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

      // Close button triggers discard dialog when data is unsaved.
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('sell.discardTitle'), findsOneWidget);
    });
  });
}
