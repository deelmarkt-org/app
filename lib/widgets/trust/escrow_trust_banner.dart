import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';

/// Trust banner displayed on listing detail and transaction screens.
///
/// Never dismissible. Background: trust-shield green.
/// Border-left: 3px trust-verified green.
///
/// Reference: docs/design-system/patterns.md §Trust Banner
class EscrowTrustBanner extends StatelessWidget {
  const EscrowTrustBanner({this.onMoreInfo, super.key});

  /// Callback when "More info" is tapped.
  final VoidCallback? onMoreInfo;

  static const double _bannerBorderWidth = 3;
  static const double _iconSize = 24;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'escrow.protected'.tr(),
      child: Container(
        padding: const EdgeInsets.all(Spacing.s4),
        decoration: const BoxDecoration(
          color: DeelmarktColors.trustShield,
          border: Border(
            left: BorderSide(
              color: DeelmarktColors.trustVerified,
              width: _bannerBorderWidth,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill),
              color: DeelmarktColors.trustVerified,
              size: _iconSize,
            ),
            const SizedBox(width: Spacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'escrow.protected'.tr(),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: DeelmarktColors.trustVerified,
                    ),
                  ),
                  const SizedBox(height: Spacing.s1),
                  Text(
                    'escrow.protectedDescription'.tr(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DeelmarktColors.neutral700,
                    ),
                  ),
                ],
              ),
            ),
            if (onMoreInfo != null)
              TextButton(
                onPressed: onMoreInfo,
                child: Text('escrow.moreInfo'.tr()),
              ),
          ],
        ),
      ),
    );
  }
}
