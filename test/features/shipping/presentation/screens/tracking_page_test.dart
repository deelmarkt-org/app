import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/shipping/data/mock/mock_shipping_repository.dart';
import 'package:deelmarkt/features/shipping/presentation/screens/tracking_page.dart';
import 'package:deelmarkt/features/shipping/presentation/screens/tracking_screen.dart';
import 'package:deelmarkt/widgets/feedback/error_state.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('TrackingPage', () {
    testWidgets('shows tracking screen for known shipping ID', (tester) async {
      await pumpTestScreenWithProviders(
        tester,
        const TrackingPage(shippingId: 'ship-001'),
        overrides: [
          shippingRepositoryProvider.overrideWithValue(
            MockShippingRepository(),
          ),
        ],
      );

      expect(find.byType(TrackingScreen), findsOneWidget);
    });

    testWidgets('shows error for unknown shipping ID', (tester) async {
      await pumpTestScreenWithProviders(
        tester,
        const TrackingPage(shippingId: 'nonexistent'),
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
