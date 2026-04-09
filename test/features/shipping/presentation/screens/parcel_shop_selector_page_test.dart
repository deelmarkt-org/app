import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/shipping/data/mock/mock_shipping_repository.dart';
import 'package:deelmarkt/features/shipping/presentation/screens/parcel_shop_selector_page.dart';
import 'package:deelmarkt/features/shipping/presentation/screens/parcel_shop_selector_screen.dart';
import 'package:deelmarkt/widgets/feedback/error_state.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('ParcelShopSelectorPage', () {
    testWidgets('shows selector for known shipping ID', (tester) async {
      await pumpTestScreenWithProviders(
        tester,
        const ParcelShopSelectorPage(shippingId: 'ship-001'),
        overrides: [
          shippingRepositoryProvider.overrideWithValue(
            MockShippingRepository(),
          ),
        ],
      );

      expect(find.byType(ParcelShopSelectorScreen), findsOneWidget);
    });

    testWidgets('shows error for unknown shipping ID', (tester) async {
      await pumpTestScreenWithProviders(
        tester,
        const ParcelShopSelectorPage(shippingId: 'nonexistent'),
        overrides: [
          shippingRepositoryProvider.overrideWithValue(
            MockShippingRepository(),
          ),
        ],
      );

      expect(find.byType(ErrorState), findsOneWidget);
    });
  });
}
