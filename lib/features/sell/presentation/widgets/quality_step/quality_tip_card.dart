import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';

/// Tip card with lightbulb icon and improvement suggestion.
///
/// Displayed on the quality step when one or more fields can be improved.
/// Uses [DeelmarktColors.infoSurface] for a subtle blue background.
class QualityTipCard extends StatelessWidget {
  const QualityTipCard({required this.tipKey, super.key});

  final String tipKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.s3),
      decoration: BoxDecoration(
        color: DeelmarktColors.infoSurface,
        borderRadius: BorderRadius.circular(DeelmarktRadius.md),
      ),
      child: Row(
        children: [
          const Icon(
            PhosphorIconsRegular.lightbulb,
            color: DeelmarktColors.info,
            size: 20,
          ),
          const SizedBox(width: Spacing.s2),
          Expanded(
            child: Text(
              tipKey.tr(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
