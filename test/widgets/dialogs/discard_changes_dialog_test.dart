import 'package:deelmarkt/widgets/dialogs/discard_changes_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tests for [DiscardChangesDialog].
///
/// Reference: docs/PLAN-P54-screen-decomposition.md §4 (PR-F1).
///
/// In test mode EasyLocalization warns when a key is not loaded but falls
/// back to the literal key — so assertions look for `'sell.discard'` rather
/// than the resolved translation. This matches the project pattern in
/// `test/widgets/cards/escrow_aware_listing_card_test.dart`.
void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  Widget buildHost({required Future<void> Function(BuildContext) onPressed}) {
    return EasyLocalization(
      supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
      fallbackLocale: const Locale('en', 'US'),
      path: 'assets/l10n',
      child: MaterialApp(
        home: Builder(
          builder:
              (innerCtx) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => onPressed(innerCtx),
                    child: const Text('open'),
                  ),
                ),
              ),
        ),
      ),
    );
  }

  testWidgets('returns true when user taps the destructive confirm', (
    tester,
  ) async {
    var result = false;
    await tester.pumpWidget(
      buildHost(
        onPressed: (ctx) async {
          result = await DiscardChangesDialog.show(
            ctx,
            titleKey: 'sell.discardTitle',
            messageKey: 'sell.discardMessage',
            confirmLabelKey: 'sell.discard',
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('sell.discard'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });

  testWidgets('returns false when user taps cancel', (tester) async {
    var result = true;
    await tester.pumpWidget(
      buildHost(
        onPressed: (ctx) async {
          result = await DiscardChangesDialog.show(
            ctx,
            titleKey: 'sell.discardTitle',
            messageKey: 'sell.discardMessage',
            confirmLabelKey: 'sell.discard',
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Default cancelLabelKey 'action.cancel'.
    await tester.tap(find.text('action.cancel'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });

  testWidgets('barrier-tap dismisses with false (never auto-discards)', (
    tester,
  ) async {
    var result = true;
    await tester.pumpWidget(
      buildHost(
        onPressed: (ctx) async {
          result = await DiscardChangesDialog.show(
            ctx,
            titleKey: 'sell.discardTitle',
            messageKey: 'sell.discardMessage',
            confirmLabelKey: 'sell.discard',
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Tap outside the dialog content (barrier).
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(
      result,
      isFalse,
      reason:
          'Barrier-tap returns null from showDialog → must coerce to false '
          'to avoid silent destructive discard.',
    );
  });

  testWidgets('destructive=true colors the confirm action red', (tester) async {
    await tester.pumpWidget(
      buildHost(
        onPressed: (ctx) async {
          await DiscardChangesDialog.show(
            ctx,
            titleKey: 'sell.discardTitle',
            messageKey: 'sell.discardMessage',
            confirmLabelKey: 'sell.discard',
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final confirmText = tester.widget<Text>(find.text('sell.discard'));
    final dialogContext = tester.element(find.text('sell.discard'));
    expect(confirmText.style?.color, Theme.of(dialogContext).colorScheme.error);
  });

  testWidgets('destructive=false leaves the confirm action default-styled', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildHost(
        onPressed: (ctx) async {
          await DiscardChangesDialog.show(
            ctx,
            titleKey: 'sell.discardTitle',
            messageKey: 'sell.discardMessage',
            confirmLabelKey: 'sell.discard',
            destructive: false,
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final confirmText = tester.widget<Text>(find.text('sell.discard'));
    final dialogContext = tester.element(find.text('sell.discard'));
    expect(
      confirmText.style?.color,
      isNot(Theme.of(dialogContext).colorScheme.error),
    );
  });

  testWidgets('honors a custom cancelLabelKey', (tester) async {
    await tester.pumpWidget(
      buildHost(
        onPressed: (ctx) async {
          await DiscardChangesDialog.show(
            ctx,
            titleKey: 'sell.discardTitle',
            messageKey: 'sell.discardMessage',
            confirmLabelKey: 'sell.discard',
            cancelLabelKey: 'sanction.screen.discard_cancel',
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('sanction.screen.discard_cancel'), findsOneWidget);
    expect(find.text('action.cancel'), findsNothing);
  });
}
