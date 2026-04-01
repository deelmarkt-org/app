import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';

/// Expandable FAQ section explaining iDIN verification.
class KycFaqExpandable extends StatelessWidget {
  const KycFaqExpandable({super.key});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        'kyc.whatIsIdin'.tr(),
        style: Theme.of(context).textTheme.titleSmall,
      ),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: Spacing.s4),
      children: [
        Text(
          'kyc.idinExplanation'.tr(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
