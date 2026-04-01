import 'package:deelmarkt/features/profile/presentation/widgets/delete_account_dialog.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('DeleteAccountDialog', () {
    Future<void> pumpDialog(WidgetTester tester) async {
      await pumpTestWidget(
        tester,
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () => DeleteAccountDialog.show(context),
              child: const Text('Open'),
            );
          },
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    testWidgets('renders title and body', (tester) async {
      await pumpDialog(tester);

      expect(find.text('settings.deleteConfirmTitle'), findsOneWidget);
      expect(find.text('settings.deleteConfirmBody'), findsOneWidget);
    });

    testWidgets('cancel returns false', (tester) async {
      bool? result;
      await pumpTestWidget(
        tester,
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                result = await DeleteAccountDialog.show(context);
              },
              child: const Text('Open'),
            );
          },
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Tap the cancel button (ghost variant with 'action.cancel' text)
      await tester.tap(find.text('action.cancel'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('confirm returns true', (tester) async {
      bool? result;
      await pumpTestWidget(
        tester,
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                result = await DeleteAccountDialog.show(context);
              },
              child: const Text('Open'),
            );
          },
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Tap the confirm/delete button (destructive variant)
      await tester.tap(find.text('settings.deleteAccount'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('uses DeelButton destructive variant', (tester) async {
      await pumpDialog(tester);

      final buttons =
          tester.widgetList<DeelButton>(find.byType(DeelButton)).toList();
      final destructiveButtons = buttons.where(
        (b) => b.variant == DeelButtonVariant.destructive,
      );

      expect(destructiveButtons, hasLength(1));
    });

    testWidgets('uses DeelButton ghost variant for cancel', (tester) async {
      await pumpDialog(tester);

      final buttons =
          tester.widgetList<DeelButton>(find.byType(DeelButton)).toList();
      final ghostButtons = buttons.where(
        (b) => b.variant == DeelButtonVariant.ghost,
      );

      expect(ghostButtons, hasLength(1));
    });
  });
}
