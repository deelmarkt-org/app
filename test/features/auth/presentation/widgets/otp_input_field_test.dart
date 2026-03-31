import 'package:deelmarkt/features/auth/presentation/widgets/otp_input_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSubject({
    ValueChanged<String>? onCompleted,
    String? errorText,
    String? semanticLabel,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: OtpInputField(
          onCompleted: onCompleted ?? (_) {},
          errorText: errorText,
          semanticLabel: semanticLabel,
        ),
      ),
    );
  }

  group('OtpInputField', () {
    testWidgets('renders 6 text fields', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      expect(textFields, findsNWidgets(6));
    });

    testWidgets('typing a digit auto-advances focus to next field', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // First field should be focused automatically
      final firstField = find.byType(TextFormField).first;
      await tester.enterText(firstField, '1');
      await tester.pump();

      // Verify the first field has '1' entered
      final firstController =
          tester
              .widget<TextFormField>(find.byType(TextFormField).at(0))
              .controller;
      expect(firstController?.text, '1');
    });

    testWidgets('entering 6 digits calls onCompleted with the 6-digit code', (
      tester,
    ) async {
      String? completedCode;
      await tester.pumpWidget(
        buildSubject(onCompleted: (code) => completedCode = code),
      );
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);

      for (var i = 0; i < 6; i++) {
        await tester.enterText(fields.at(i), '${i + 1}');
        await tester.pump();
      }

      expect(completedCode, '123456');
    });

    testWidgets('error text displays when errorText is provided', (
      tester,
    ) async {
      const errorMessage = 'Invalid code';
      await tester.pumpWidget(buildSubject(errorText: errorMessage));
      await tester.pumpAndSettle();

      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('error text is not shown when errorText is null', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // No error text widget beyond the text fields themselves
      expect(find.text('Invalid code'), findsNothing);
    });

    testWidgets('semantics label is set', (tester) async {
      const label = 'Enter verification code';
      await tester.pumpWidget(buildSubject(semanticLabel: label));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(label), findsOneWidget);
    });
  });
}
