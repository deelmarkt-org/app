import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/admin/presentation/screens/admin_shell_screen.dart';

void main() {
  group('AdminShellScreen', () {
    test('can be constructed with a child widget', () {
      // AdminShellScreen requires GoRouter context for GoRouterState.of,
      // so full rendering is tested in integration tests.
      // This verifies the constructor compiles correctly.
      const screen = AdminShellScreen(child: SizedBox.shrink());
      expect(screen.child, isA<SizedBox>());
    });
  });
}
