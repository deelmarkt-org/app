import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/shipping/domain/entities/parcel_shop.dart';
import 'package:deelmarkt/features/shipping/presentation/widgets/parcel_shop_list_item.dart';

import '../../../../helpers/pump_app.dart';

const _kShop = ParcelShop(
  id: 'shop-001',
  name: 'PostNL Puntenstraat',
  address: 'Puntenstraat 12',
  postalCode: '1234 AB',
  city: 'Amsterdam',
  latitude: 52.37,
  longitude: 4.89,
  distanceKm: 0.8,
  carrier: ParcelShopCarrier.postnl,
  openToday: '08:00–20:00',
);

void main() {
  group('ParcelShopListItem — Semantics regression (issue #156 H2)', () {
    testWidgets('has Semantics with button:true', (tester) async {
      await pumpTestWidget(
        tester,
        ParcelShopListItem(shop: _kShop, onTap: () {}),
      );

      final semanticsList =
          tester.widgetList<Semantics>(find.byType(Semantics)).toList();
      final buttonSemantics =
          semanticsList.where((s) => s.properties.button == true).toList();

      expect(
        buttonSemantics,
        isNotEmpty,
        reason:
            'ParcelShopListItem must expose button: true for TalkBack / '
            'VoiceOver (WCAG 4.1.2)',
      );
    });

    testWidgets('Semantics label contains shop name', (tester) async {
      await pumpTestWidget(
        tester,
        ParcelShopListItem(shop: _kShop, onTap: () {}),
      );

      final semanticsList =
          tester.widgetList<Semantics>(find.byType(Semantics)).toList();
      final withLabel =
          semanticsList
              .where(
                (s) =>
                    s.properties.label != null &&
                    s.properties.label!.contains(_kShop.name),
              )
              .toList();

      expect(
        withLabel,
        isNotEmpty,
        reason: 'Semantics label must contain the shop name',
      );
    });

    testWidgets('selected state is reflected in Semantics', (tester) async {
      await pumpTestWidget(
        tester,
        ParcelShopListItem(shop: _kShop, onTap: () {}, isSelected: true),
      );

      final semanticsList =
          tester.widgetList<Semantics>(find.byType(Semantics)).toList();
      final selectedSemantics =
          semanticsList.where((s) => s.properties.selected == true).toList();

      expect(
        selectedSemantics,
        isNotEmpty,
        reason: 'isSelected must be forwarded to Semantics.selected',
      );
    });
  });
}
