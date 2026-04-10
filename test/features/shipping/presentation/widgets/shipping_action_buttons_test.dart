import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/shipping/presentation/widgets/shipping_action_buttons.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('ShippingActionButtons', () {
    testWidgets('renders three buttons', (tester) async {
      await pumpTestWidget(
        tester,
        const ShippingActionButtons(shippingId: 'ship-001'),
      );

      expect(find.byType(DeelButton), findsNWidgets(3));
    });

    testWidgets('buttons have correct labels', (tester) async {
      await pumpTestWidget(
        tester,
        const ShippingActionButtons(shippingId: 'ship-001'),
      );

      expect(find.textContaining('shipping.viewQrCode'), findsOneWidget);
      expect(find.textContaining('tracking.viewTracking'), findsOneWidget);
      expect(find.textContaining('shipping.findServicePoint'), findsOneWidget);
    });
  });
}
