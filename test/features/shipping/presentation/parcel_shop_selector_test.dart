import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/shipping/domain/entities/parcel_shop.dart';
import 'package:deelmarkt/features/shipping/presentation/screens/parcel_shop_selector_screen.dart';
import 'package:deelmarkt/features/shipping/presentation/widgets/parcel_shop_list_item.dart';

import '../../../../test/helpers/pump_app.dart';

List<ParcelShop> _shops() => [
  const ParcelShop(
    id: 'ps_1',
    name: 'AH Amsterdam Centrum',
    address: 'Damrak 1',
    postalCode: '1012 LG',
    city: 'Amsterdam',
    latitude: 52.3738,
    longitude: 4.8910,
    distanceKm: 0.3,
    carrier: ParcelShopCarrier.postnl,
    openToday: '08:00–22:00',
  ),
  const ParcelShop(
    id: 'ps_2',
    name: 'DHL ServicePoint Centraal',
    address: 'Stationsplein 10',
    postalCode: '1012 AB',
    city: 'Amsterdam',
    latitude: 52.3791,
    longitude: 4.9003,
    distanceKm: 0.8,
    carrier: ParcelShopCarrier.dhl,
    openToday: '09:00–18:00',
  ),
  const ParcelShop(
    id: 'ps_3',
    name: 'Bruna Jordaan',
    address: 'Elandsgracht 44',
    postalCode: '1016 TT',
    city: 'Amsterdam',
    latitude: 52.3680,
    longitude: 4.8810,
    distanceKm: 1.5,
    carrier: ParcelShopCarrier.postnl,
  ),
];

void main() {
  group('ParcelShopSelectorScreen', () {
    testWidgets('renders list of shops', (tester) async {
      await pumpTestScreen(tester, ParcelShopSelectorScreen(shops: _shops()));

      expect(find.byType(ParcelShopListItem), findsNWidgets(3));
    });

    testWidgets('shows shop names', (tester) async {
      await pumpTestScreen(tester, ParcelShopSelectorScreen(shops: _shops()));

      expect(find.text('AH Amsterdam Centrum'), findsOneWidget);
      expect(find.text('DHL ServicePoint Centraal'), findsOneWidget);
      expect(find.text('Bruna Jordaan'), findsOneWidget);
    });

    testWidgets('shows distances', (tester) async {
      await pumpTestScreen(tester, ParcelShopSelectorScreen(shops: _shops()));

      expect(find.text('0.3'), findsOneWidget);
      expect(find.text('0.8'), findsOneWidget);
      expect(find.text('1.5'), findsOneWidget);
    });

    testWidgets('tapping shop selects it', (tester) async {
      await pumpTestScreen(tester, ParcelShopSelectorScreen(shops: _shops()));

      await tester.tap(find.text('AH Amsterdam Centrum'));
      await tester.pumpAndSettle();

      // Select bar appears on compact layout
      expect(find.textContaining('shipping.selectThisShop'), findsWidgets);
    });

    testWidgets('shows empty state with no shops', (tester) async {
      await pumpTestScreen(tester, const ParcelShopSelectorScreen(shops: []));

      expect(find.textContaining('shipping.noShopsFound'), findsOneWidget);
      expect(find.byType(ParcelShopListItem), findsNothing);
    });

    testWidgets('has app bar with title', (tester) async {
      await pumpTestScreen(tester, ParcelShopSelectorScreen(shops: _shops()));

      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('shop items have Semantics', (tester) async {
      await pumpTestScreen(tester, ParcelShopSelectorScreen(shops: _shops()));

      final semantics = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.button == true &&
            w.properties.label != null &&
            w.properties.label!.contains('AH Amsterdam'),
      );
      expect(semantics, findsOneWidget);
    });

    testWidgets('shows opening hours when available', (tester) async {
      await pumpTestScreen(tester, ParcelShopSelectorScreen(shops: _shops()));

      // First two shops have openToday, third doesn't
      expect(find.textContaining('shipping.openUntil'), findsNWidgets(2));
    });
  });
}
