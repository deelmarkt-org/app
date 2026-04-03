import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/profile/presentation/widgets/addresses_section.dart';
import 'package:deelmarkt/features/shipping/domain/entities/dutch_address.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  const testAddresses = [
    DutchAddress(
      postcode: '1012 AB',
      houseNumber: '42',
      street: 'Damstraat',
      city: 'Amsterdam',
    ),
    DutchAddress(
      postcode: '3011 HE',
      houseNumber: '15',
      addition: 'B',
      street: 'Coolsingel',
      city: 'Rotterdam',
    ),
  ];

  group('AddressesSection', () {
    testWidgets('renders all addresses as formatted text', (tester) async {
      await pumpTestWidget(
        tester,
        AddressesSection(
          addresses: testAddresses,
          onAdd: () {},
          onEdit: (_) {},
          onDelete: (_) {},
        ),
      );

      // Verify formatted addresses appear.
      expect(find.text('Damstraat 42, 1012 AB Amsterdam'), findsOneWidget);
      expect(find.text('Coolsingel 15 B, 3011 HE Rotterdam'), findsOneWidget);
    });

    testWidgets('renders section header', (tester) async {
      await pumpTestWidget(
        tester,
        AddressesSection(
          addresses: testAddresses,
          onAdd: () {},
          onEdit: (_) {},
          onDelete: (_) {},
        ),
      );

      // .tr() returns the key path in tests.
      expect(find.text('settings.addresses'), findsOneWidget);
    });

    testWidgets('add button renders with label', (tester) async {
      await pumpTestWidget(
        tester,
        AddressesSection(
          addresses: const [],
          onAdd: () {},
          onEdit: (_) {},
          onDelete: (_) {},
        ),
      );

      expect(find.text('settings.addAddress'), findsOneWidget);
    });

    testWidgets('tapping add button fires onAdd callback', (tester) async {
      var addCalled = false;

      await pumpTestWidget(
        tester,
        AddressesSection(
          addresses: const [],
          onAdd: () => addCalled = true,
          onEdit: (_) {},
          onDelete: (_) {},
        ),
      );

      await tester.tap(find.text('settings.addAddress'));
      await tester.pumpAndSettle();

      expect(addCalled, isTrue);
    });

    testWidgets('edit icon button fires onEdit with correct address', (
      tester,
    ) async {
      DutchAddress? editedAddress;

      await pumpTestWidget(
        tester,
        AddressesSection(
          addresses: const [
            DutchAddress(
              postcode: '1012 AB',
              houseNumber: '42',
              street: 'Damstraat',
              city: 'Amsterdam',
            ),
          ],
          onAdd: () {},
          onEdit: (address) => editedAddress = address,
          onDelete: (_) {},
        ),
      );

      // Tap the edit button (tooltip: 'action.edit').
      await tester.tap(find.byTooltip('action.edit'));
      await tester.pumpAndSettle();

      expect(editedAddress, isNotNull);
      expect(editedAddress!.postcode, equals('1012 AB'));
    });

    testWidgets('delete icon button fires onDelete with correct address', (
      tester,
    ) async {
      DutchAddress? deletedAddress;

      await pumpTestWidget(
        tester,
        AddressesSection(
          addresses: const [
            DutchAddress(
              postcode: '1012 AB',
              houseNumber: '42',
              street: 'Damstraat',
              city: 'Amsterdam',
            ),
          ],
          onAdd: () {},
          onEdit: (_) {},
          onDelete: (address) => deletedAddress = address,
        ),
      );

      await tester.tap(find.byTooltip('action.delete'));
      await tester.pumpAndSettle();

      expect(deletedAddress, isNotNull);
      expect(deletedAddress!.postcode, equals('1012 AB'));
    });

    testWidgets('renders empty list without errors', (tester) async {
      await pumpTestWidget(
        tester,
        AddressesSection(
          addresses: const [],
          onAdd: () {},
          onEdit: (_) {},
          onDelete: (_) {},
        ),
      );

      // Only the header and add button should be present.
      expect(find.text('settings.addresses'), findsOneWidget);
      expect(find.text('settings.addAddress'), findsOneWidget);
    });
  });
}
