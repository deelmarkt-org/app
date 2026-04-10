import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/services/shared_prefs_provider.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/listing_creation_viewmodel.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/sell_providers.dart';
import 'package:deelmarkt/features/sell/presentation/widgets/photo_step/photo_step_view.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

import '../../../../../helpers/pump_app.dart';
import '../../viewmodels/viewmodel_test_helpers.dart';

/// Stub notifier that returns a fixed [ListingCreationState].
class _StubListingCreationNotifier extends ListingCreationNotifier {
  _StubListingCreationNotifier(this._state);

  final ListingCreationState _state;

  @override
  ListingCreationState build() => _state;
}

List<Override> buildOverrides(
  SharedPreferences prefs,
  ListingCreationState state,
) => [
  sharedPreferencesProvider.overrideWithValue(prefs),
  listingCreationNotifierProvider.overrideWith(
    () => _StubListingCreationNotifier(state),
  ),
  imagePickerServiceProvider.overrideWithValue(MockImagePickerService()),
  imageUploadRepositoryProvider.overrideWithValue(FakeImageUploadRepository()),
  listingCreationRepositoryProvider.overrideWithValue(
    MockListingCreationRepository(),
  ),
];

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  // Suppress overflow and image errors in constrained test viewports.
  final origOnError = FlutterError.onError;
  setUp(
    () =>
        FlutterError.onError = (details) {
          final s = details.exceptionAsString();
          if (s.contains('overflowed') || s.contains('Image')) return;
          FlutterError.dumpErrorToConsole(details);
        },
  );
  tearDown(() => FlutterError.onError = origOnError);

  group('PhotoStepView', () {
    testWidgets('renders without error with empty imageFiles', (tester) async {
      const state = ListingCreationState();

      await pumpTestScreenWithProviders(
        tester,
        const Scaffold(
          body: Column(children: [Expanded(child: PhotoStepView())]),
        ),
        overrides: buildOverrides(prefs, state),
      );

      // PhotoStepView must be present in the tree.
      expect(find.byType(PhotoStepView), findsOneWidget);
    });

    testWidgets('shows photosCount l10n key with empty imageFiles', (
      tester,
    ) async {
      const state = ListingCreationState();

      await pumpTestScreenWithProviders(
        tester,
        const Scaffold(
          body: Column(children: [Expanded(child: PhotoStepView())]),
        ),
        overrides: buildOverrides(prefs, state),
      );

      // .tr() returns the l10n key in test environments.
      expect(find.text('sell.photosCount'), findsOneWidget);
    });

    testWidgets('shows add photos button when imageFiles is empty', (
      tester,
    ) async {
      const state = ListingCreationState();

      await pumpTestScreenWithProviders(
        tester,
        const Scaffold(
          body: Column(children: [Expanded(child: PhotoStepView())]),
        ),
        overrides: buildOverrides(prefs, state),
      );

      // At least two DeelButtons should be present: add photos + next.
      expect(find.byType(DeelButton), findsWidgets);

      final addPhotosButton = tester
          .widgetList<DeelButton>(find.byType(DeelButton))
          .firstWhere(
            (b) => b.variant == DeelButtonVariant.outline,
            orElse: () => throw StateError('no outline button found'),
          );

      expect(addPhotosButton.variant, equals(DeelButtonVariant.outline));
    });

    testWidgets('next button is disabled when imageFiles is empty', (
      tester,
    ) async {
      const state = ListingCreationState();

      await pumpTestScreenWithProviders(
        tester,
        const Scaffold(
          body: Column(children: [Expanded(child: PhotoStepView())]),
        ),
        overrides: buildOverrides(prefs, state),
      );

      // The last DeelButton is the "next" button.
      final nextButton =
          tester.widgetList<DeelButton>(find.byType(DeelButton)).last;

      // With empty imageFiles, allImagesUploaded is false → onPressed null.
      expect(nextButton.onPressed, isNull);
    });
  });
}
