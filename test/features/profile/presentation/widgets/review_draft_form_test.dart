import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/profile/domain/entities/review_entity.dart';
import 'package:deelmarkt/features/profile/presentation/notifiers/review_screen_state.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/review_draft_form.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/rating_input.dart';
import 'package:deelmarkt/widgets/trust/trust_banner.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('ReviewDraftForm', () {
    ReviewDraftState makeDraft({
      double rating = 0,
      String body = '',
      bool hasRestoredDraft = false,
    }) {
      return ReviewDraftState(
        rating: rating,
        body: body,
        idempotencyKey: 'key-1',
        revieweeName: 'review.role.seller',
        role: ReviewRole.seller,
        hasRestoredDraft: hasRestoredDraft,
      );
    }

    testWidgets('renders RatingInput', (tester) async {
      await pumpTestScreen(
        tester,
        Scaffold(
          body: ReviewDraftForm(
            draft: makeDraft(),
            onRatingChanged: (_) {},
            onBodyChanged: (_) {},
            onSubmit: () {},
          ),
        ),
      );

      expect(find.byType(ReviewDraftForm), findsOneWidget);
      expect(find.byType(RatingInput), findsOneWidget);
    });

    testWidgets('submit button disabled when canSubmit is false', (
      tester,
    ) async {
      await pumpTestScreen(
        tester,
        Scaffold(
          body: ReviewDraftForm(
            draft: makeDraft(),
            onRatingChanged: (_) {},
            onBodyChanged: (_) {},
            onSubmit: () {},
          ),
        ),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('submit button enabled when canSubmit is true', (tester) async {
      await pumpTestScreen(
        tester,
        Scaffold(
          body: ReviewDraftForm(
            draft: makeDraft(rating: 4, body: 'Great item!'),
            onRatingChanged: (_) {},
            onBodyChanged: (_) {},
            onSubmit: () {},
          ),
        ),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('onSubmit fires when button tapped', (tester) async {
      var submitted = false;

      await pumpTestScreen(
        tester,
        Scaffold(
          body: ReviewDraftForm(
            draft: makeDraft(rating: 4, body: 'Great!'),
            onRatingChanged: (_) {},
            onBodyChanged: (_) {},
            onSubmit: () => submitted = true,
          ),
        ),
      );

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(submitted, isTrue);
    });

    testWidgets('shows TrustBanner when hasRestoredDraft is true', (
      tester,
    ) async {
      await pumpTestScreen(
        tester,
        Scaffold(
          body: ReviewDraftForm(
            draft: makeDraft(hasRestoredDraft: true),
            onRatingChanged: (_) {},
            onBodyChanged: (_) {},
            onSubmit: () {},
          ),
        ),
      );

      expect(find.byType(TrustBanner), findsOneWidget);
    });

    testWidgets('hides TrustBanner when hasRestoredDraft is false', (
      tester,
    ) async {
      await pumpTestScreen(
        tester,
        Scaffold(
          body: ReviewDraftForm(
            draft: makeDraft(),
            onRatingChanged: (_) {},
            onBodyChanged: (_) {},
            onSubmit: () {},
          ),
        ),
      );

      expect(find.byType(TrustBanner), findsNothing);
    });
  });
}
