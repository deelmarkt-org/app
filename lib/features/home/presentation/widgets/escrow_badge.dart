import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/icon_sizes.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';

/// Small inline escrow badge: shield icon + "Escrow beschikbaar".
class EscrowBadge extends StatelessWidget {
  const EscrowBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill),
          size: DeelmarktIconSize.xs,
          color: DeelmarktColors.trustEscrow,
        ),
        const SizedBox(width: Spacing.s1),
        Text(
          'listing_card.escrowAvailable'.tr(),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: DeelmarktColors.trustEscrow),
        ),
      ],
    );
  }
}
