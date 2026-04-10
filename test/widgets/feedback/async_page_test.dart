import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/widgets/feedback/async_page.dart';
import 'package:deelmarkt/widgets/feedback/error_state.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('AsyncPage', () {
    testWidgets('shows loading indicator when loading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AsyncPage<String>(
            title: 'Test',
            state: AsyncValue.loading(),
            onRetry: _noop,
            builder: _textBuilder,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error state on error', (tester) async {
      await pumpTestScreen(
        tester,
        AsyncPage<String>(
          title: 'Test',
          state: AsyncValue.error(Exception('fail'), StackTrace.empty),
          onRetry: _noop,
          builder: _textBuilder,
        ),
      );

      expect(find.byType(ErrorState), findsOneWidget);
    });

    testWidgets('shows builder content on data', (tester) async {
      await pumpTestScreen(
        tester,
        const AsyncPage<String>(
          title: 'Test',
          state: AsyncValue.data('hello'),
          onRetry: _noop,
          builder: _textBuilder,
        ),
      );

      expect(find.text('hello'), findsOneWidget);
    });
  });
}

void _noop() {}

Widget _textBuilder(String data) => Scaffold(body: Center(child: Text(data)));
