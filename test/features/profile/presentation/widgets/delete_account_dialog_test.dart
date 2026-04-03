import 'package:deelmarkt/features/profile/presentation/widgets/delete_account_dialog.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';

Widget _dialogOpener({ValueChanged<String?>? onResult}) {
  return Scaffold(
    body: Builder(
      builder: (context) {
        return ElevatedButton(
          onPressed: () async {
            final result = await DeleteAccountDialog.show(context);
            onResult?.call(result);
          },
          child: const Text('Open'),
        );
      },
    ),
  );
}

void main() {
  group('DeleteAccountDialog', () {
    Future<void> pumpDialog(WidgetTester tester) async {
      await pumpTestScreenWithProviders(tester, _dialogOpener());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    testWidgets('renders title, body, and password field', (tester) async {
      await pumpDialog(tester);

      expect(find.text('settings.deleteConfirmTitle'), findsOneWidget);
      expect(find.text('settings.deleteConfirmBody'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('cancel returns null', (tester) async {
      String? result = 'not-null';
      await pumpTestScreenWithProviders(
        tester,
        _dialogOpener(onResult: (r) => result = r),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('action.cancel'));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });

    testWidgets('confirm with password returns password', (tester) async {
      String? result;
      await pumpTestScreenWithProviders(
        tester,
        _dialogOpener(onResult: (r) => result = r),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'my-password');
      await tester.tap(find.text('settings.deleteAccount'));
      await tester.pumpAndSettle();

      expect(result, 'my-password');
    });

    testWidgets('confirm without password does not dismiss', (tester) async {
      await pumpDialog(tester);

      await tester.tap(find.text('settings.deleteAccount'));
      await tester.pumpAndSettle();

      expect(find.text('settings.deleteConfirmTitle'), findsOneWidget);
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
