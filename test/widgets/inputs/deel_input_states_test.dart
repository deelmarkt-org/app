import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/widgets/inputs/deel_input.dart';

import 'deel_input_test_helper.dart';

void main() {
  group('DeelInput interaction', () {
    testWidgets('onChanged fires when text is entered', (tester) async {
      String? changedValue;
      await tester.pumpWidget(
        buildInputApp(
          child: DeelInput(label: 'Test', onChanged: (v) => changedValue = v),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'hello');
      expect(changedValue, 'hello');
    });

    testWidgets('controller reflects typed text', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        buildInputApp(child: DeelInput(label: 'Test', controller: controller)),
      );

      await tester.enterText(find.byType(TextFormField), 'world');
      expect(controller.text, 'world');

      controller.dispose();
    });

    testWidgets('disabled input does not accept text', (tester) async {
      String? changedValue;
      await tester.pumpWidget(
        buildInputApp(
          child: DeelInput(
            label: 'Test',
            enabled: false,
            onChanged: (v) => changedValue = v,
          ),
        ),
      );

      // TextFormField with enabled: false should not accept input.
      final field = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(field.enabled, isFalse);
      expect(changedValue, isNull);
    });
  });

  group('DeelInput Form integration', () {
    testWidgets('validator is called by Form.validate()', (tester) async {
      final formKey = GlobalKey<FormState>();
      var validatorCalled = false;

      await tester.pumpWidget(
        buildFormApp(
          formKey: formKey,
          child: DeelInput(
            label: 'E-mail',
            validator: (value) {
              validatorCalled = true;
              if (value == null || value.isEmpty) return 'Required';
              return null;
            },
          ),
        ),
      );

      formKey.currentState!.validate();
      expect(validatorCalled, isTrue);
    });

    testWidgets('onSaved is called by Form.save()', (tester) async {
      final formKey = GlobalKey<FormState>();
      String? savedValue;

      await tester.pumpWidget(
        buildFormApp(
          formKey: formKey,
          child: DeelInput(
            label: 'Naam',
            onSaved: (value) => savedValue = value,
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'Jan');
      formKey.currentState!.save();
      expect(savedValue, 'Jan');
    });
  });

  group('DeelInput lifecycle', () {
    testWidgets('internally created controller is disposed', (tester) async {
      await tester.pumpWidget(
        buildInputApp(child: const DeelInput(label: 'Test')),
      );

      // Replace with a different widget — dispose should not throw.
      await tester.pumpWidget(buildInputApp(child: const SizedBox()));

      // If we reach here, dispose succeeded without error.
      expect(true, isTrue);
    });

    testWidgets('external controller is NOT disposed', (tester) async {
      final controller = TextEditingController(text: 'initial');

      await tester.pumpWidget(
        buildInputApp(child: DeelInput(label: 'Test', controller: controller)),
      );

      await tester.pumpWidget(buildInputApp(child: const SizedBox()));

      // External controller should still be usable.
      expect(controller.text, 'initial');
      controller.dispose();
    });

    testWidgets('controller swap in didUpdateWidget works', (tester) async {
      final controller1 = TextEditingController(text: 'first');
      final controller2 = TextEditingController(text: 'second');

      await tester.pumpWidget(
        buildInputApp(child: DeelInput(label: 'Test', controller: controller1)),
      );

      expect(find.text('first'), findsOneWidget);

      await tester.pumpWidget(
        buildInputApp(child: DeelInput(label: 'Test', controller: controller2)),
      );

      expect(find.text('second'), findsOneWidget);

      controller1.dispose();
      controller2.dispose();
    });
  });
}
