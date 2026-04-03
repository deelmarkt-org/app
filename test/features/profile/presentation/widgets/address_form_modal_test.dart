import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/profile/presentation/widgets/address_form_modal.dart';
import 'package:deelmarkt/features/shipping/domain/entities/dutch_address.dart';
import 'package:deelmarkt/features/shipping/presentation/widgets/dutch_address_input.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('AddressFormModal', () {
    testWidgets('renders add mode title when no address provided', (
      tester,
    ) async {
      await pumpTestWidget(tester, AddressFormModal(onSave: (_) {}));

      expect(find.text('settings.addAddress'), findsOneWidget);
    });

    testWidgets('renders edit mode title when address provided', (
      tester,
    ) async {
      const address = DutchAddress(
        postcode: '1012 AB',
        houseNumber: '42',
        street: 'Damstraat',
        city: 'Amsterdam',
      );

      await pumpTestWidget(
        tester,
        AddressFormModal(address: address, onSave: (_) {}),
      );

      expect(find.text('settings.editAddress'), findsOneWidget);
    });

    testWidgets('contains DutchAddressInput widget', (tester) async {
      await pumpTestWidget(tester, AddressFormModal(onSave: (_) {}));

      expect(find.byType(DutchAddressInput), findsOneWidget);
    });

    testWidgets('renders save and cancel buttons', (tester) async {
      await pumpTestWidget(tester, AddressFormModal(onSave: (_) {}));

      expect(find.text('action.save'), findsOneWidget);
      expect(find.text('action.cancel'), findsOneWidget);
    });

    testWidgets('shows validation errors on empty save', (tester) async {
      await pumpTestWidget(tester, AddressFormModal(onSave: (_) {}));

      await tester.tap(find.text('action.save'));
      await tester.pumpAndSettle();

      expect(find.text('address.postcodeInvalid'), findsOneWidget);
      expect(find.text('address.houseNumberInvalid'), findsOneWidget);
      expect(find.text('address.streetRequired'), findsOneWidget);
      expect(find.text('address.cityRequired'), findsOneWidget);
    });

    testWidgets('calls onSave with valid input', (tester) async {
      DutchAddress? savedAddress;

      await pumpTestWidget(
        tester,
        AddressFormModal(onSave: (address) => savedAddress = address),
      );

      // TextFormFields: 0=postcode, 1=houseNumber, 2=addition, 3=street, 4=city
      await tester.enterText(find.byType(TextFormField).at(0), '1012 AB');
      await tester.enterText(find.byType(TextFormField).at(1), '42');
      await tester.enterText(find.byType(TextFormField).at(3), 'Damstraat');
      await tester.enterText(find.byType(TextFormField).at(4), 'Amsterdam');
      await tester.pumpAndSettle();

      await tester.tap(find.text('action.save'));
      await tester.pumpAndSettle();

      expect(savedAddress, isNotNull);
      expect(savedAddress!.postcode, '1012 AB');
      expect(savedAddress!.houseNumber, '42');
      expect(savedAddress!.street, 'Damstraat');
      expect(savedAddress!.city, 'Amsterdam');
    });

    testWidgets('pre-fills fields in edit mode', (tester) async {
      const address = DutchAddress(
        postcode: '3011 HE',
        houseNumber: '15',
        addition: 'B',
        street: 'Coolsingel',
        city: 'Rotterdam',
      );

      await pumpTestWidget(
        tester,
        AddressFormModal(address: address, onSave: (_) {}),
      );

      final postcodeField = tester.widget<TextFormField>(
        find.byType(TextFormField).first,
      );
      expect(postcodeField.controller?.text, '3011 HE');
    });
  });
}
