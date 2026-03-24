import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/shipping/presentation/widgets/dutch_address_input.dart';

import '../../../../test/helpers/pump_app.dart';

void main() {
  late TextEditingController postcodeCtrl;
  late TextEditingController houseNumberCtrl;
  late TextEditingController additionCtrl;

  setUp(() {
    postcodeCtrl = TextEditingController();
    houseNumberCtrl = TextEditingController();
    additionCtrl = TextEditingController();
  });

  tearDown(() {
    postcodeCtrl.dispose();
    houseNumberCtrl.dispose();
    additionCtrl.dispose();
  });

  Widget buildWidget({String? street, String? city, bool isLoading = false}) {
    return DutchAddressInput(
      postcodeController: postcodeCtrl,
      houseNumberController: houseNumberCtrl,
      additionController: additionCtrl,
      street: street,
      city: city,
      isLoading: isLoading,
    );
  }

  group('DutchAddressInput', () {
    testWidgets('renders all 5 fields', (tester) async {
      await pumpTestWidget(tester, buildWidget());

      // Postcode, house number, addition = 3 TextFormFields
      // Street, city = 2 InputDecorators (read-only auto-filled)
      expect(find.byType(TextFormField), findsNWidgets(3));
      expect(find.byType(InputDecorator), findsWidgets);
    });

    testWidgets('shows auto-filled street and city', (tester) async {
      await pumpTestWidget(
        tester,
        buildWidget(street: 'Damrak', city: 'Amsterdam'),
      );

      expect(find.text('Damrak'), findsOneWidget);
      expect(find.text('Amsterdam'), findsOneWidget);
    });

    testWidgets('shows loading indicator when looking up address', (
      tester,
    ) async {
      // Use pump (not pumpAndSettle) — CircularProgressIndicator animates indefinitely
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: buildWidget(isLoading: true)),
          ),
        ),
      );
      await tester.pump();

      expect(find.bySubtype<CircularProgressIndicator>(), findsOneWidget);
    });

    testWidgets('shows postcode error when provided', (tester) async {
      await pumpTestWidget(
        tester,
        DutchAddressInput(
          postcodeController: postcodeCtrl,
          houseNumberController: houseNumberCtrl,
          postcodeError: 'Invalid postcode',
        ),
      );

      expect(find.text('Invalid postcode'), findsOneWidget);
    });

    testWidgets('shows house number error when provided', (tester) async {
      await pumpTestWidget(
        tester,
        DutchAddressInput(
          postcodeController: postcodeCtrl,
          houseNumberController: houseNumberCtrl,
          houseNumberError: 'Required',
        ),
      );

      expect(find.text('Required'), findsOneWidget);
    });

    testWidgets('has Semantics on all fields', (tester) async {
      await pumpTestWidget(tester, buildWidget());

      final semantics = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.textField == true,
      );
      expect(semantics, findsNWidgets(5));
    });

    testWidgets('auto-filled fields show success styling', (tester) async {
      await pumpTestWidget(
        tester,
        buildWidget(street: 'Damrak', city: 'Amsterdam'),
      );

      // Helper text "auto-filled" appears for both street and city
      expect(find.textContaining('address.autoFilled'), findsNWidgets(2));
    });
  });
}
