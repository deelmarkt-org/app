import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/sell/domain/entities/quality_score_result.dart';

/// Single row in the quality score breakdown.
///
/// Shows pass/fail icon, field name, points earned vs max,
/// and an optional improvement tip when the field fails.
class QualityBreakdownRow extends StatelessWidget {
  const QualityBreakdownRow({required this.field, super.key});

  final QualityScoreField field;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${field.name.tr()}: ${field.points}/${field.maxPoints}',
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                field.passed
                    ? PhosphorIconsFill.checkCircle
                    : PhosphorIconsFill.xCircle,
                color:
                    field.passed
                        ? DeelmarktColors.success
                        : DeelmarktColors.error,
                size: 20,
              ),
              const SizedBox(width: Spacing.s2),
              Expanded(
                child: Text(
                  field.name.tr(),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Text(
                '${field.points}/${field.maxPoints}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DeelmarktColors.neutral700,
                ),
              ),
            ],
          ),
          if (!field.passed && field.tipKey != null)
            Padding(
              padding: const EdgeInsets.only(
                left: Spacing.s6 + Spacing.s2,
                top: Spacing.s1,
              ),
              child: Text(
                field.tipKey!.tr(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DeelmarktColors.neutral700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
