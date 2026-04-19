import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/icon_sizes.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/design_system/trust_theme.dart';

/// Inline KYC banner for Level 0 users — prompts phone verification.
///
/// Never blocks browsing. Contextual and non-intrusive.
class KycBanner extends StatelessWidget {
  const KycBanner({required this.onVerify, super.key});

  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    final trustTheme =
        Theme.of(context).extension<DeelmarktTrustTheme>() ??
        DeelmarktTrustTheme.light();

    return Semantics(
      label: 'kyc.bannerTitle'.tr(),
      child: Container(
        padding: const EdgeInsets.all(Spacing.s4),
        decoration: BoxDecoration(
          color: trustTheme.shield,
          border: Border(left: BorderSide(color: trustTheme.warning, width: 3)),
        ),
        child: Row(
          children: [
            Icon(
              PhosphorIcons.shieldWarning(PhosphorIconsStyle.duotone),
              color: trustTheme.warning,
              size: DeelmarktIconSize.md,
            ),
            const SizedBox(width: Spacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'kyc.bannerTitle'.tr(),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: Spacing.s1),
                  Text(
                    'kyc.bannerSubtitle'.tr(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onVerify,
              child: Text('kyc.bannerAction'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
