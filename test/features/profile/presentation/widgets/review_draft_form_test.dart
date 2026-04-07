import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/features/profile/domain/entities/review_entity.dart';
import 'package:deelmarkt/features/profile/presentation/notifiers/review_screen_state.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/rating_input.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/review_draft_form.dart';

/// Helper — creates a [ReviewDraftState] for testing.
ReviewDraftState _draft({
  double rating = 0,
  String body = '',
  bool hasRestoredDraft = false,
}) => ReviewDraftState(
  rating: rating,
  body: body,
  idempotencyKey: 'idempotency-key-1',
  revieweeName: 'review.roleSeller',
  role: ReviewRole.buyer,
  hasRestoredDraft: hasRestoredDraft,
);

/// Pumps [form] inside a [Scaffold] so that [BottomAppBar] and [Expanded]
/// have proper height constraints.
Future<void> _pump(WidgetTester tester, ReviewDraftForm form) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: DeelmarktTheme.light,
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Scaffold(body: form),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ReviewDraftForm — rendering', () {
    testWidgets('renders RatingInput', (tester) async {
      await _pump(
        tester,
        ReviewDraftForm(
          draft: _draft(),
          onRatingChanged: (_) {},
          onBodyChanged: (_) {},
          onSubmit: () {},
        ),
      );
      expect(find.byType(RatingInput), findsOneWidget);
    });

    testWidgets('renders submit button', (tester) async {
      await _pump(
        tester,
        ReviewDraftForm(
          draft: _draft(),
          onRatingChanged: (_) {},
          onBodyChanged: (_) {},
          onSubmit: () {},
        ),
      );
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('shows how-was-experience prompt with reviewee name', (
      tester,
    ) async {
      await _pump(
        tester,
        ReviewDraftForm(
          draft: _draft(),
          onRatingChanged: (_) {},
          onBodyChanged: (_) {},
          onSubmit: () {},
        ),
      );
      // .tr() returns the key in test env; named arg 'name' is also a key
      expect(find.text('review.howWasExperience'), findsOneWidget);
    });

    testWidgets('shows character counter', (tester) async {
      await _pump(
        tester,
        ReviewDraftForm(
          draft: _draft(body: 'Hello'),
          onRatingChanged: (_) {},
          onBodyChanged: (_) {},
          onSubmit: () {},
        ),
      );
      expect(find.text('review.charCounter'), findsOneWidget);
    });
  });

  group('ReviewDraftForm — trust banner', () {
    testWidgets('shows blind-review banner when hasRestoredDraft', (
      tester,
    ) async {
      await _pump(
        tester,
        ReviewDraftForm(
          draft: _draft(hasRestoredDraft: true),
          onRatingChanged: (_) {},
          onBodyChanged: (_) {},
          onSubmit: () {},
        ),
      );
      expect(find.text('review.blindReview'), findsOneWidget);
    });

    testWidgets('hides banner when draft was not restored', (tester) async {
      await _pump(
        tester,
        ReviewDraftForm(
          draft: _draft(),
          onRatingChanged: (_) {},
          onBodyChanged: (_) {},
          onSubmit: () {},
        ),
      );
      expect(find.text('review.blindReview'), findsNothing);
    });
  });

  group('ReviewDraftForm — submit button state', () {
    testWidgets('submit is disabled when rating is zero', (tester) async {
      await _pump(
        tester,
        ReviewDraftForm(
          draft: _draft(body: 'Some text'),
          onRatingChanged: (_) {},
          onBodyChanged: (_) {},
          onSubmit: () {},
        ),
      );
      final btn = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(btn.onPressed, isNull);
    });

    testWidgets('submit is enabled when canSubmit is true', (tester) async {
      var submitted = false;
      await _pump(
        tester,
        ReviewDraftForm(
          draft: _draft(rating: 4, body: 'Great seller!'),
          onRatingChanged: (_) {},
          onBodyChanged: (_) {},
          onSubmit: () => submitted = true,
        ),
      );
      await tester.tap(find.byType(FilledButton));
      expect(submitted, isTrue);
    });
  });

  group('ReviewDraftForm — dark mode', () {
    testWidgets('renders without errors in dark theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: DeelmarktTheme.dark,
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: ReviewDraftForm(
                draft: _draft(rating: 3, body: 'Good'),
                onRatingChanged: (_) {},
                onBodyChanged: (_) {},
                onSubmit: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ReviewDraftForm), findsOneWidget);
    });
  });
}
