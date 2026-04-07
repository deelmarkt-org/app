import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/listing_creation_viewmodel.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/sell_providers.dart';
import 'package:deelmarkt/features/sell/presentation/widgets/quality_step/quality_breakdown_row.dart';
import 'package:deelmarkt/features/sell/presentation/widgets/quality_step/quality_score_ring.dart';
import 'package:deelmarkt/features/sell/presentation/widgets/quality_step/quality_tip_card.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

/// Step 3: Quality score display with publish/draft actions.
///
/// Watches [qualityScoreProvider] (auto-derived from form state).
/// Shows score ring, per-field breakdown, improvement tips,
/// and publish/draft buttons.
class QualityStepView extends ConsumerWidget {
  const QualityStepView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = ref.watch(qualityScoreProvider);
    final state = ref.watch(listingCreationNotifierProvider);
    final notifier = ref.read(listingCreationNotifierProvider.notifier);

    final firstTip =
        score.breakdown
            .where((f) => !f.passed && f.tipKey != null)
            .map((f) => f.tipKey!)
            .firstOrNull;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.s4),
      child: Column(
        children: [
          const SizedBox(height: Spacing.s6),
          QualityScoreRing(score: score.score),
          const SizedBox(height: Spacing.s6),

          // Per-field breakdown.
          ...score.breakdown.map(
            (field) => Padding(
              padding: const EdgeInsets.only(bottom: Spacing.s2),
              child: QualityBreakdownRow(field: field),
            ),
          ),

          const SizedBox(height: Spacing.s4),

          // Tip card for first failing field.
          if (firstTip != null) QualityTipCard(tipKey: firstTip),

          if (!score.canPublish) ...[
            const SizedBox(height: Spacing.s3),
            Text(
              'sell.qualityTooLow'.tr(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: Spacing.s8),

          // Publish button — disabled if score < 40.
          DeelButton(
            label: 'sell.publish'.tr(),
            onPressed: score.canPublish ? () => notifier.publish() : null,
            isLoading: state.isLoading,
          ),
          const SizedBox(height: Spacing.s3),

          // Save draft button.
          DeelButton(
            label: 'sell.saveDraft'.tr(),
            variant: DeelButtonVariant.ghost,
            onPressed: state.isLoading ? null : () => notifier.saveDraft(),
          ),
          const SizedBox(height: Spacing.s4),
        ],
      ),
    );
  }
}
