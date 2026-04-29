import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/domain/entities/scam_reason.dart';
import 'package:deelmarkt/features/profile/domain/entities/scam_flag_statement.dart';

/// Section wrapper used by [ScamFlagStatementOfReasons] — uppercase-styled
/// label + child content.
///
/// Extracted from the main widget to keep the parent file ≤200 LOC
/// (CLAUDE.md §2.1) and to make each section independently testable.
class ScamStatementSection extends StatelessWidget {
  const ScamStatementSection({
    required this.title,
    required this.child,
    super.key,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: DeelmarktColors.neutral500,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: Spacing.s1),
        child,
      ],
    );
  }
}

/// Bullet list of localised [ScamReason]s. Reuses the existing
/// `scam_alert.reason.*` l10n keys via [ScamReason.localizationKey] so
/// adding a new reason on the backend surfaces here AND in the chat
/// banner without copy duplication.
class ScamReasonsList extends StatelessWidget {
  const ScamReasonsList({required this.reasons, super.key});

  final List<ScamReason> reasons;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final reason in reasons)
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.s1),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6, right: Spacing.s2),
                  child: Icon(
                    PhosphorIconsRegular.dotOutline,
                    size: 12,
                    color: DeelmarktColors.neutral500,
                  ),
                ),
                Expanded(
                  child: Text(
                    reason.localizationKey.tr(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: DeelmarktColors.neutral700,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// "How was this decision made?" block: the four DSA-required transparency
/// strings (automated indicator, confidence%, model version, policy
/// version) so the appellant can cite the exact decision-maker.
class ScamDecisionMetadata extends StatelessWidget {
  const ScamDecisionMetadata({required this.statement, super.key});

  final ScamFlagStatement statement;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: DeelmarktColors.neutral500,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('dsa.statement_of_reasons.automated_indicator'.tr(), style: style),
        const SizedBox(height: Spacing.s1),
        Text(
          'dsa.statement_of_reasons.confidence'.tr(
            namedArgs: {'percent': '${statement.confidencePercent}'},
          ),
          style: style,
        ),
        Text(
          'dsa.statement_of_reasons.model_version'.tr(
            namedArgs: {'version': statement.modelVersion},
          ),
          style: style,
        ),
        Text(
          'dsa.statement_of_reasons.policy_version'.tr(
            namedArgs: {'version': statement.policyVersion},
          ),
          style: style,
        ),
      ],
    );
  }
}
