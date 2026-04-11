import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';
import 'package:deelmarkt/features/sell/presentation/widgets/live_preview_panel.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  // Suppress image decode and overflow errors in test viewports.
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

  group('LivePreviewPanel', () {
    testWidgets('renders without error when imageFiles is empty', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        const SizedBox(
          height: 500,
          child: LivePreviewPanel(state: ListingCreationState()),
        ),
      );

      // The panel wraps content in a Card — it should be present.
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('shows placeholder icon when imageFiles is empty', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        const SizedBox(
          height: 500,
          child: LivePreviewPanel(state: ListingCreationState()),
        ),
      );

      // Placeholder uses Icons.image_outlined.
      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    });

    testWidgets('shows Image.file widget when imageFiles is non-empty', (
      tester,
    ) async {
      const state = ListingCreationState(
        imageFiles: [
          SellImage(
            id: 'img-1',
            localPath: '/non/existent/path.jpg',
            status: ImageUploadStatus.uploaded,
          ),
        ],
      );

      await pumpTestWidget(
        tester,
        const SizedBox(height: 500, child: LivePreviewPanel(state: state)),
      );

      // Image.file is rendered; file errors fall through to errorBuilder
      // which shows Icons.image — both confirm the branch was entered.
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('shows title placeholder text when title is empty', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        const SizedBox(
          height: 500,
          child: LivePreviewPanel(state: ListingCreationState()),
        ),
      );

      // .tr() returns the l10n key in test environments.
      expect(find.text('sell.previewTitlePlaceholder'), findsOneWidget);
    });

    testWidgets('shows title when state.title is non-empty', (tester) async {
      await pumpTestWidget(
        tester,
        const SizedBox(
          height: 500,
          child: LivePreviewPanel(
            state: ListingCreationState(title: 'Vintage Camera'),
          ),
        ),
      );

      expect(find.text('Vintage Camera'), findsOneWidget);
    });

    testWidgets('shows fallback price when priceInCents is zero', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        const SizedBox(
          height: 500,
          child: LivePreviewPanel(state: ListingCreationState()),
        ),
      );

      expect(find.text('\u20AC 0,00'), findsOneWidget);
    });

    testWidgets('shows formatted price when priceInCents is non-zero', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        const SizedBox(
          height: 500,
          child: LivePreviewPanel(
            state: ListingCreationState(priceInCents: 1999),
          ),
        ),
      );

      expect(find.text('\u20AC 19.99'), findsOneWidget);
    });

    testWidgets('shows preview section header l10n key', (tester) async {
      await pumpTestWidget(
        tester,
        const SizedBox(
          height: 500,
          child: LivePreviewPanel(state: ListingCreationState()),
        ),
      );

      // .tr() returns key path in test environments without loaded translations.
      expect(find.text('sell.livePreview'), findsOneWidget);
    });
  });
}
