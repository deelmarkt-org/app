import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/design_system/trust_theme.dart';

/// Variant of the trust banner.
enum TrustBannerVariant { escrowProtection, info }

/// A non-dismissible trust banner with icon, title, description, and
/// optional "More info" action.
///
/// Two named constructors:
/// - [TrustBanner.escrow]: pre-configured for escrow protection messaging.
/// - [TrustBanner.info]: configurable for general trust/info messaging.
///
/// Uses [DeelmarktTrustTheme] for dark mode support (fixes hardcoded colour
/// bug in the original [EscrowTrustBanner]).
///
/// Reference: docs/design-system/patterns.md §Trust Banner
class TrustBanner extends StatelessWidget {
  /// Escrow protection variant with pre-configured text and icon.
  const TrustBanner.escrow({this.onMoreInfo, super.key})
    : variant = TrustBannerVariant.escrowProtection,
      title = null,
      description = null,
      icon = null;

  /// General info variant with custom title, description, and optional icon.
  const TrustBanner.info({
    required String this.title,
    required String this.description,
    this.icon,
    this.onMoreInfo,
    super.key,
  }) : variant = TrustBannerVariant.info;

  final TrustBannerVariant variant;
  final String? title;
  final String? description;
  final IconData? icon;
  final VoidCallback? onMoreInfo;

  static const double _bannerBorderWidth = 3;
  static const double _iconSize = 24;

  @override
  Widget build(BuildContext context) {
    final trustTheme =
        Theme.of(context).extension<DeelmarktTrustTheme>() ??
        DeelmarktTrustTheme.light();

    final resolvedTitle = _resolveTitle();
    final resolvedDescription = _resolveDescription();
    final resolvedIcon = _resolveIcon();
    final accentColor = _accentColor(trustTheme);
    final backgroundColor = _backgroundColor(trustTheme);

    return Semantics(
      label: resolvedTitle,
      child: Container(
        padding: const EdgeInsets.all(Spacing.s4),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(
            left: BorderSide(color: accentColor, width: _bannerBorderWidth),
          ),
        ),
        child: Row(
          children: [
            Icon(resolvedIcon, color: accentColor, size: _iconSize),
            const SizedBox(width: Spacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resolvedTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: Spacing.s1),
                  Text(
                    resolvedDescription,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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

  String _resolveTitle() {
    if (variant == TrustBannerVariant.escrowProtection) {
      return 'escrow.protected'.tr();
    }
    return title ?? '';
  }

  String _resolveDescription() {
    if (variant == TrustBannerVariant.escrowProtection) {
      return 'escrow.protectedDescription'.tr();
    }
    return description ?? '';
  }

  IconData _resolveIcon() {
    if (variant == TrustBannerVariant.escrowProtection) {
      return PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill);
    }
    return icon ?? PhosphorIcons.info(PhosphorIconsStyle.fill);
  }

  Color _accentColor(DeelmarktTrustTheme theme) {
    return switch (variant) {
      TrustBannerVariant.escrowProtection => theme.verified,
      TrustBannerVariant.info => theme.escrow,
    };
  }

  Color _backgroundColor(DeelmarktTrustTheme theme) {
    return switch (variant) {
      TrustBannerVariant.escrowProtection => theme.shield,
      TrustBannerVariant.info => theme.shield,
    };
  }
}
