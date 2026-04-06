import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/profile/presentation/notifiers/review_screen_state.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/rating_input.dart';
import 'package:deelmarkt/widgets/inputs/deel_input.dart';
import 'package:deelmarkt/widgets/trust/trust_banner.dart';

/// Draft form body for the review screen.
///
/// Contains rating stars, text input with character counter,
/// blind review explanation banner, and submit bar.
class ReviewDraftForm extends StatefulWidget {
  const ReviewDraftForm({
    required this.draft,
    required this.onRatingChanged,
    required this.onBodyChanged,
    required this.onSubmit,
    super.key,
  });

  final ReviewDraftState draft;
  final ValueChanged<double> onRatingChanged;
  final ValueChanged<String> onBodyChanged;
  final VoidCallback onSubmit;

  @override
  State<ReviewDraftForm> createState() => _ReviewDraftFormState();
}

class _ReviewDraftFormState extends State<ReviewDraftForm> {
  late TextEditingController _bodyController;

  @override
  void initState() {
    super.initState();
    _bodyController = TextEditingController(text: widget.draft.body);
  }

  @override
  void didUpdateWidget(ReviewDraftForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draft.body != widget.draft.body &&
        _bodyController.text != widget.draft.body) {
      _bodyController.value = TextEditingValue(
        text: widget.draft.body,
        selection: TextSelection.collapsed(offset: widget.draft.body.length),
      );
    }
  }

  @override
  void dispose() {
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final charCount = widget.draft.body.length;
    final counterColor = _counterColor(charCount);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.s4),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.draft.hasRestoredDraft) ...[
                    TrustBanner.info(
                      title: 'review.blindReview'.tr(),
                      description: 'review.blindExplanation'.tr(),
                      icon: PhosphorIcons.shield(PhosphorIconsStyle.fill),
                    ),
                    const SizedBox(height: Spacing.s4),
                  ],
                  Text(
                    'review.howWasExperience'.tr(
                      namedArgs: {'name': widget.draft.revieweeName.tr()},
                    ),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: Spacing.s4),
                  RatingInput(
                    value: widget.draft.rating,
                    onChanged: widget.onRatingChanged,
                  ),
                  const SizedBox(height: Spacing.s6),
                  DeelInput(
                    label: 'review.tellAbout'.tr(),
                    maxLines: 5,
                    maxLength: 500,
                    controller: _bodyController,
                    onChanged: widget.onBodyChanged,
                  ),
                  const SizedBox(height: Spacing.s2),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Semantics(
                      label: 'review.a11y.counter'.tr(),
                      child: Text(
                        'review.charCounter'.tr(
                          namedArgs: {'current': '$charCount'},
                        ),
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: counterColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        BottomAppBar(
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: widget.draft.canSubmit ? widget.onSubmit : null,
              child: Text('review.submit'.tr()),
            ),
          ),
        ),
      ],
    );
  }

  Color _counterColor(int chars) {
    if (chars > 490) return DeelmarktColors.error;
    if (chars > 450) return DeelmarktColors.warning;
    return DeelmarktColors.neutral500;
  }
}
