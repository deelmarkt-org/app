/// Tests for appeal_parts.dart sub-widgets and helpers.
///
/// Covers: [appealExceptionToL10nKey], [AppealCharCounter],
/// [AppealSanctionSummaryCard], and [AppealFormBody].
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/profile/domain/entities/sanction_entity.dart';
import 'package:deelmarkt/features/profile/domain/exceptions/sanction_exceptions.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/appeal_parts.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

import '../../../../helpers/pump_app.dart';

// ── helpers ──────────────────────────────────────────────────────────────────

SanctionEntity _suspension({String id = 'sanction-1'}) {
  return SanctionEntity(
    id: id,
    userId: 'user-1',
    type: SanctionType.suspension,
    reason: 'Test reason',
    // ignore: avoid_redundant_argument_values
    createdAt: DateTime(2026, 4, 1),
    // ignore: avoid_redundant_argument_values
    expiresAt: DateTime(2026, 5, 1),
  );
}

// ── appealExceptionToL10nKey ─────────────────────────────────────────────────

void main() {
  group('appealExceptionToL10nKey', () {
    test('AppealWindowExpired → appeal_window_closed', () {
      expect(
        appealExceptionToL10nKey(const AppealWindowExpired()),
        'sanction.screen.appeal_window_closed',
      );
    });

    test('AppealAlreadyResolved → appeal_upheld_body', () {
      expect(
        appealExceptionToL10nKey(const AppealAlreadyResolved()),
        'sanction.screen.appeal_upheld_body',
      );
    });

    test('AppealRateLimited → error.generic', () {
      expect(
        appealExceptionToL10nKey(const AppealRateLimited()),
        'error.generic',
      );
    });

    test('SanctionNotFound → error.generic', () {
      expect(
        appealExceptionToL10nKey(const SanctionNotFound()),
        'error.generic',
      );
    });

    test('Unknown error → error.generic', () {
      expect(appealExceptionToL10nKey(Exception('random')), 'error.generic');
    });
  });

  // ── AppealCharCounter ───────────────────────────────────────────────────────

  group('AppealCharCounter', () {
    testWidgets('shows count / 1000', (tester) async {
      await pumpTestWidget(tester, const AppealCharCounter(charCount: 42));
      expect(find.text('42 / 1000'), findsOneWidget);
    });

    testWidgets('shows 0 / 1000 for empty body', (tester) async {
      await pumpTestWidget(tester, const AppealCharCounter(charCount: 0));
      expect(find.text('0 / 1000'), findsOneWidget);
    });

    testWidgets('shows 1000 / 1000 at limit', (tester) async {
      await pumpTestWidget(tester, const AppealCharCounter(charCount: 1000));
      expect(find.text('1000 / 1000'), findsOneWidget);
    });
  });

  // ── AppealSanctionSummaryCard ───────────────────────────────────────────────

  group('AppealSanctionSummaryCard', () {
    testWidgets('renders sanction reason', (tester) async {
      await pumpTestWidget(
        tester,
        AppealSanctionSummaryCard(sanction: _suspension()),
      );
      expect(find.text('Test reason'), findsOneWidget);
    });
  });

  // ── AppealFormBody ──────────────────────────────────────────────────────────

  group('AppealFormBody', () {
    testWidgets('submit button enabled when isValid=true', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      bool submitted = false;

      await pumpTestWidget(
        tester,
        AppealFormBody(
          sanction: _suspension(),
          controller: controller,
          onChanged: (_) {},
          isSubmitting: false,
          isValid: true,
          charCount: 50,
          onSubmit: () => submitted = true,
        ),
      );

      final button = find.byType(DeelButton);
      expect(button, findsOneWidget);
      await tester.tap(button);
      expect(submitted, isTrue);
    });

    testWidgets('submit button disabled when isValid=false', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpTestWidget(
        tester,
        AppealFormBody(
          sanction: _suspension(),
          controller: controller,
          onChanged: (_) {},
          isSubmitting: false,
          isValid: false,
          charCount: 5,
          onSubmit: null,
        ),
      );

      final button = tester.widget<DeelButton>(find.byType(DeelButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('shows loading when isSubmitting=true', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      // Use animated pump — isLoading shows a CircularProgressIndicator
      // with an infinite animation that causes pumpAndSettle to time out.
      await pumpTestWidgetAnimated(
        tester,
        AppealFormBody(
          sanction: _suspension(),
          controller: controller,
          onChanged: (_) {},
          isSubmitting: true,
          isValid: true,
          charCount: 50,
          onSubmit: null,
        ),
      );

      final button = tester.widget<DeelButton>(find.byType(DeelButton));
      expect(button.isLoading, isTrue);
    });

    testWidgets('calls onChanged when text field changes', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      String? changedValue;

      await pumpTestWidget(
        tester,
        AppealFormBody(
          sanction: _suspension(),
          controller: controller,
          onChanged: (v) => changedValue = v,
          isSubmitting: false,
          isValid: false,
          charCount: 0,
          onSubmit: null,
        ),
      );

      await tester.enterText(find.byType(TextField), 'hello world');
      expect(changedValue, 'hello world');
    });
  });
}
