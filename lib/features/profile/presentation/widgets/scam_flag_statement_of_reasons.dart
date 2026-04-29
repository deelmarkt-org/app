import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/icon_sizes.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/profile/domain/entities/scam_flag_statement.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/scam_flag_statement_parts.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

/// User-facing **Statement of Reasons** for an automated content-moderation
/// decision (DSA Art. 17 / EU AI Act Art. 13 transparency).
///
/// Surfaces the four DSA-required transparency fields in a single panel:
///   * `What was flagged?`     — opaque `contentRef`
///   * `Why?`                  — localised reason list (closed enum)
///   * `How?`                  — automated indicator + model + policy versions
///   * `What can you do?`      — Appeal CTA → existing P-53 appeal screen
///
/// Designed to embed inside [SuspensionGateScreen] when a sanction is
/// auto-issued, OR above any flagged content surface (listing/profile/
/// message). Caller wires the appeal navigation via [onAppeal] and passes
/// a [ScamFlagStatement] populated by the backend (R-44).
///
/// Reference:
/// - docs/audits/2026-04-25-tier1-retrospective.md §R-44
/// - docs/screens/01-auth/06-suspension-gate.md
/// - docs/screens/01-auth/07-appeal-form.md
class ScamFlagStatementOfReasons extends StatelessWidget {
  const ScamFlagStatementOfReasons({
    required this.statement,
    this.onAppeal,
    super.key,
  });

  final ScamFlagStatement statement;

  /// Fired when the user taps the Appeal CTA. When null, the CTA is hidden
  /// (WCAG 4.1.2 — interactive elements must have a determinable purpose).
  final VoidCallback? onAppeal;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'dsa.statement_of_reasons.a11y'.tr(),
      container: true,
      explicitChildNodes: true,
      child: Container(
        padding: const EdgeInsets.all(Spacing.s4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(DeelmarktRadius.xl),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            const SizedBox(height: Spacing.s3),
            ScamStatementSection(
              title: 'dsa.statement_of_reasons.what_flagged'.tr(),
              child: Text(
                statement.contentRef,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: Spacing.s3),
            ScamStatementSection(
              title: 'dsa.statement_of_reasons.why'.tr(),
              child: ScamReasonsList(reasons: statement.reasons),
            ),
            const SizedBox(height: Spacing.s3),
            ScamStatementSection(
              title: 'dsa.statement_of_reasons.how'.tr(),
              child: ScamDecisionMetadata(statement: statement),
            ),
            if (onAppeal != null) ...[
              const SizedBox(height: Spacing.s4),
              DeelButton(
                label: 'dsa.statement_of_reasons.appeal_cta'.tr(),
                onPressed: onAppeal,
                size: DeelButtonSize.medium,
                leadingIcon: PhosphorIconsRegular.scales,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(Spacing.s2),
          decoration: const BoxDecoration(
            color: DeelmarktColors.warningSurface,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            PhosphorIconsRegular.flag,
            size: DeelmarktIconSize.sm,
            color: DeelmarktColors.warning,
          ),
        ),
        const SizedBox(width: Spacing.s3),
        Expanded(
          child: Text(
            'dsa.statement_of_reasons.headline'.tr(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
