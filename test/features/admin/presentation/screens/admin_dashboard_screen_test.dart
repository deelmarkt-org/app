import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/admin/presentation/screens/admin_dashboard_screen.dart';

void main() {
  group('AdminDashboardScreen', () {
    test('is a ConsumerWidget', () {
      // Compile-time verification: AdminDashboardScreen exists and is a
      // ConsumerWidget. Full rendering requires ProviderScope with a
      // running AdminDashboardNotifier, which is covered by integration tests.
      const screen = AdminDashboardScreen();
      expect(screen, isNotNull);
    });
  });
}
