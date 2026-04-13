import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/domain/entities/dutch_address.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/delete_address_dialog.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

import '../../../../helpers/pump_app.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _testAddress = DutchAddress(
  postcode: '1012 AB',
  houseNumber: '42',
  street: 'Damrak',
  city: 'Amsterdam',
);

Widget _dialogOpener({ValueChanged<bool?>? onResult}) {
  return Scaffold(
    body: Builder(
      builder:
          (context) => ElevatedButton(
            onPressed: () async {
              final result = await DeleteAddressDialog.show(
                context,
                _testAddress,
              );
              onResult?.call(result);
            },
            child: const Text('Open'),
          ),
    ),
  );
}

Future<void> _pumpDialog(WidgetTester tester) async {
  await pumpTestScreenWithProviders(tester, _dialogOpener());
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('DeleteAddressDialog', () {
    testWidgets('renders title and formatted address', (tester) async {
      await _pumpDialog(tester);

      expect(find.text('settings.deleteAddressTitle'), findsOneWidget);
      expect(find.text(_testAddress.formatted), findsOneWidget);
    });

    testWidgets('confirm returns true', (tester) async {
      bool? result;
      await pumpTestScreenWithProviders(
        tester,
        _dialogOpener(onResult: (r) => result = r),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('action.delete'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('cancel returns null', (tester) async {
      bool? result = true;
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

    testWidgets(
      'barrierDismissible is false — tapping outside keeps dialog open',
      (tester) async {
        await _pumpDialog(tester);

        // Tap the barrier area (top-left corner, outside the dialog bounds).
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        expect(find.text('settings.deleteAddressTitle'), findsOneWidget);
      },
    );

    testWidgets('uses DeelButton destructive variant for delete', (
      tester,
    ) async {
      await _pumpDialog(tester);

      final buttons =
          tester.widgetList<DeelButton>(find.byType(DeelButton)).toList();
      final destructiveButtons = buttons.where(
        (b) => b.variant == DeelButtonVariant.destructive,
      );

      expect(destructiveButtons, hasLength(1));
    });

    testWidgets('uses DeelButton ghost variant for cancel', (tester) async {
      await _pumpDialog(tester);

      final buttons =
          tester.widgetList<DeelButton>(find.byType(DeelButton)).toList();
      final ghostButtons = buttons.where(
        (b) => b.variant == DeelButtonVariant.ghost,
      );

      expect(ghostButtons, hasLength(1));
    });
  });
}
