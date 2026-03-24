import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/widgets/inputs/deel_input_controller_mixin.dart';

// Minimal test widget that uses the mixin.
class _TestWidget extends StatefulWidget {
  const _TestWidget({this.controller});

  final TextEditingController? controller;

  @override
  State<_TestWidget> createState() => _TestWidgetState();
}

class _TestWidgetState extends State<_TestWidget>
    with DeelInputControllerMixin<_TestWidget> {
  @override
  TextEditingController? get externalController => widget.controller;

  @override
  void initState() {
    super.initState();
    initInputController();
  }

  @override
  void didUpdateWidget(_TestWidget old) {
    super.didUpdateWidget(old);
    updateInputController(old.controller);
  }

  @override
  void dispose() {
    disposeInputController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(controller: inputController);
  }
}

Widget buildApp({TextEditingController? controller}) {
  return MaterialApp(
    theme: DeelmarktTheme.light,
    home: Scaffold(body: _TestWidget(controller: controller)),
  );
}

void main() {
  group('DeelInputControllerMixin ownership', () {
    testWidgets('creates internal controller when none provided', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.controller, isNotNull);
    });

    testWidgets('uses external controller when provided', (tester) async {
      final external = TextEditingController(text: 'hello');
      addTearDown(external.dispose);
      await tester.pumpWidget(buildApp(controller: external));
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.controller, same(external));
    });

    testWidgets('internal controller allows text manipulation', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.enterText(find.byType(TextField), 'test');
      expect(find.text('test'), findsOneWidget);
    });
  });

  group('DeelInputControllerMixin swapping', () {
    testWidgets('switching from null to external uses new controller', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      final external = TextEditingController(text: 'swapped');
      addTearDown(external.dispose);
      await tester.pumpWidget(buildApp(controller: external));
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.controller, same(external));
    });

    testWidgets('switching from external to null creates internal', (
      tester,
    ) async {
      final external = TextEditingController(text: 'ext');
      addTearDown(external.dispose);
      await tester.pumpWidget(buildApp(controller: external));
      await tester.pumpWidget(buildApp());
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.controller, isNot(same(external)));
    });

    testWidgets('switching between two externals uses latest', (tester) async {
      final first = TextEditingController(text: 'first');
      final second = TextEditingController(text: 'second');
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      await tester.pumpWidget(buildApp(controller: first));
      await tester.pumpWidget(buildApp(controller: second));
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.controller, same(second));
    });
  });
}
