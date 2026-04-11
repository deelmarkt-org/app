import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';
import 'package:deelmarkt/features/sell/presentation/widgets/photo_step/photo_step_view.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

import '../../../../../helpers/pump_app.dart';
import '_photo_step_test_helpers.dart';

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

  group('PhotoStepView — rendering', () {
    testWidgets('renders without error with empty imageFiles', (tester) async {
      const state = ListingCreationState();

      await pumpTestScreenWithProviders(
        tester,
        const Scaffold(
          body: Column(children: [Expanded(child: PhotoStepView())]),
        ),
        overrides: buildPhotoStepOverrides(prefs, state),
      );

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
        overrides: buildPhotoStepOverrides(prefs, state),
      );

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
        overrides: buildPhotoStepOverrides(prefs, state),
      );

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
        overrides: buildPhotoStepOverrides(prefs, state),
      );

      final nextButton =
          tester.widgetList<DeelButton>(find.byType(DeelButton)).last;
      expect(nextButton.onPressed, isNull);
    });

    testWidgets('next button is enabled when all images uploaded', (
      tester,
    ) async {
      const state = ListingCreationState(
        imageFiles: [
          SellImage(
            id: 'a',
            localPath: '/img/a.jpg',
            status: ImageUploadStatus.uploaded,
          ),
        ],
      );

      await pumpTestScreenWithProviders(
        tester,
        const Scaffold(
          body: Column(children: [Expanded(child: PhotoStepView())]),
        ),
        overrides: buildPhotoStepOverrides(prefs, state),
      );

      final nextButton =
          tester.widgetList<DeelButton>(find.byType(DeelButton)).last;

      expect(nextButton.onPressed, isNotNull);
    });

    testWidgets('hides add-photos button when imageFiles reaches max (12)', (
      tester,
    ) async {
      final images = List.generate(
        12,
        (i) => SellImage(
          id: '$i',
          localPath: '/img/$i.jpg',
          status: ImageUploadStatus.uploaded,
        ),
      );
      final state = ListingCreationState(imageFiles: images);

      await pumpTestScreenWithProviders(
        tester,
        const Scaffold(
          body: Column(children: [Expanded(child: PhotoStepView())]),
        ),
        overrides: buildPhotoStepOverrides(prefs, state),
      );

      final buttons =
          tester.widgetList<DeelButton>(find.byType(DeelButton)).toList();
      final outlineButtons = buttons.where(
        (b) => b.variant == DeelButtonVariant.outline,
      );

      expect(outlineButtons, isEmpty);
      expect(buttons.length, equals(1));
    });

    testWidgets('next button tap invokes notifier.nextStep when enabled', (
      tester,
    ) async {
      const state = ListingCreationState(
        imageFiles: [
          SellImage(
            id: 'a',
            localPath: '/img/a.jpg',
            status: ImageUploadStatus.uploaded,
          ),
        ],
      );
      final stub = StubListingCreationNotifier(state);

      await pumpTestScreenWithProviders(
        tester,
        const Scaffold(
          body: Column(children: [Expanded(child: PhotoStepView())]),
        ),
        overrides: buildPhotoStepOverrides(prefs, state, stub: stub),
      );

      final nextButton =
          tester.widgetList<DeelButton>(find.byType(DeelButton)).last;
      nextButton.onPressed!();
      await tester.pump();

      expect(stub.nextStepCalls, equals(1));
    });
  });
}
