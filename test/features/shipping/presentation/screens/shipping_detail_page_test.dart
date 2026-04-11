import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/shipping/data/mock/mock_shipping_repository.dart';
import 'package:deelmarkt/features/shipping/presentation/screens/shipping_detail_page.dart';
import 'package:deelmarkt/features/shipping/presentation/screens/shipping_detail_screen.dart';
import 'package:deelmarkt/widgets/feedback/error_state.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('ShippingDetailPage', () {
    testWidgets('shows data for known shipping ID', (tester) async {
      await pumpTestScreenWithProviders(
        tester,
        const ShippingDetailPage(shippingId: 'ship-001'),
        overrides: [
          shippingRepositoryProvider.overrideWithValue(
            MockShippingRepository(),
          ),
        ],
      );

      expect(find.byType(ShippingDetailScreen), findsOneWidget);
    });

    testWidgets('shows error for unknown shipping ID', (tester) async {
      await pumpTestScreenWithProviders(
        tester,
        const ShippingDetailPage(shippingId: 'nonexistent'),
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
