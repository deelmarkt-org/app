import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';
import 'package:deelmarkt/features/sell/presentation/widgets/photo_step/photo_step_view.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

import '../../../../../helpers/pump_app.dart';
import '_photo_step_test_helpers.dart';

/// Helper to tap the outline "Add photos" button in the view and open the
/// picker bottom sheet. Reduces boilerplate across interaction tests.
Future<void> _openPickerSheet(WidgetTester tester) async {
  await tester.tap(
    find.byWidgetPredicate(
      (w) => w is DeelButton && w.variant == DeelButtonVariant.outline,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

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

  group('PhotoStepView — picker sheet', () {
    testWidgets('tapping add-photos opens picker bottom sheet', (tester) async {
      const state = ListingCreationState();

      await pumpTestScreenWithProviders(
        tester,
        const Scaffold(
          body: Column(children: [Expanded(child: PhotoStepView())]),
        ),
        overrides: buildPhotoStepOverrides(prefs, state),
      );

      await _openPickerSheet(tester);

      expect(find.text('sell.takePhoto'), findsOneWidget);
      expect(find.text('sell.chooseFromGallery'), findsOneWidget);
    });

    testWidgets('tapping camera ListTile calls notifier.addFromCamera', (
      tester,
    ) async {
      const state = ListingCreationState();
      final stub = StubListingCreationNotifier(state);

      await pumpTestScreenWithProviders(
        tester,
        const Scaffold(
          body: Column(children: [Expanded(child: PhotoStepView())]),
        ),
        overrides: buildPhotoStepOverrides(prefs, state, stub: stub),
      );

      await _openPickerSheet(tester);
      await tester.tap(find.text('sell.takePhoto'));
      await tester.pumpAndSettle();

      expect(stub.cameraCalls, equals(1));
    });

    testWidgets('tapping gallery ListTile calls notifier.addFromGallery', (
      tester,
    ) async {
      const state = ListingCreationState();
      final stub = StubListingCreationNotifier(state);

      await pumpTestScreenWithProviders(
        tester,
        const Scaffold(
          body: Column(children: [Expanded(child: PhotoStepView())]),
        ),
        overrides: buildPhotoStepOverrides(prefs, state, stub: stub),
      );

      await _openPickerSheet(tester);
      await tester.tap(find.text('sell.chooseFromGallery'));
      await tester.pumpAndSettle();

      expect(stub.galleryCalls, equals(1));
    });
  });

  group('PhotoStepView — picker error handling', () {
    Future<void> pumpAndTriggerCamera(
      WidgetTester tester,
      String errorKey,
    ) async {
      const state = ListingCreationState();
      final stub = StubListingCreationNotifier(
        state,
        afterPickErrorKey: errorKey,
      );

      await pumpTestScreenWithProviders(
        tester,
        const Scaffold(
          body: Column(children: [Expanded(child: PhotoStepView())]),
        ),
        overrides: buildPhotoStepOverrides(prefs, state, stub: stub),
      );

      await _openPickerSheet(tester);
      await tester.tap(find.text('sell.takePhoto'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    Future<void> pumpAndTriggerGallery(
      WidgetTester tester,
      String errorKey,
    ) async {
      const state = ListingCreationState();
      final stub = StubListingCreationNotifier(
        state,
        afterPickErrorKey: errorKey,
      );

      await pumpTestScreenWithProviders(
        tester,
        const Scaffold(
          body: Column(children: [Expanded(child: PhotoStepView())]),
        ),
        overrides: buildPhotoStepOverrides(prefs, state, stub: stub),
      );

      await _openPickerSheet(tester);
      await tester.tap(find.text('sell.chooseFromGallery'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    testWidgets(
      'errorPermissionPermanent shows AlertDialog with cancel action',
      (tester) async {
        const state = ListingCreationState();
        final stub = StubListingCreationNotifier(
          state,
          afterPickErrorKey: 'sell.errorPermissionPermanent',
        );

        await pumpTestScreenWithProviders(
          tester,
          const Scaffold(
            body: Column(children: [Expanded(child: PhotoStepView())]),
          ),
          overrides: buildPhotoStepOverrides(prefs, state, stub: stub),
        );

        await _openPickerSheet(tester);
        await tester.tap(find.text('sell.takePhoto'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('action.cancel'), findsOneWidget);

        await tester.tap(find.text('action.cancel'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
      },
    );

    testWidgets('errorPermissionDenied shows SnackBar', (tester) async {
      await pumpAndTriggerCamera(tester, 'sell.errorPermissionDenied');
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('errorFileTooLarge shows SnackBar', (tester) async {
      await pumpAndTriggerGallery(tester, 'sell.errorFileTooLarge');
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('errorUnsupportedFormat shows SnackBar', (tester) async {
      await pumpAndTriggerGallery(tester, 'sell.errorUnsupportedFormat');
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('unknown error falls back to gallery permission snackbar', (
      tester,
    ) async {
      await pumpAndTriggerCamera(tester, 'sell.someUnknownError');
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
