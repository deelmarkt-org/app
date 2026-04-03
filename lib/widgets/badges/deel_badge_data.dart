import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/deel_badge_theme.dart';
import 'package:deelmarkt/features/profile/domain/entities/user_entity.dart';

/// Visual badge types for the presentation layer.
///
/// Separate from domain [BadgeType] because:
/// - Domain has types without visual badges (fastResponder, newUser)
/// - UI needs types not in domain (escrowProtected, businessSeller)
enum DeelBadgeType {
  emailVerified,
  phoneVerified,
  idinVerified,
  idVerified,
  businessSeller,
  escrowProtected,
  topSeller;

  /// Bridge from domain [BadgeType] to presentation [DeelBadgeType].
  /// Returns `null` for domain types that have no visual badge.
  static DeelBadgeType? fromBadgeType(BadgeType badgeType) {
    return switch (badgeType) {
      BadgeType.emailVerified => DeelBadgeType.emailVerified,
      BadgeType.phoneVerified => DeelBadgeType.phoneVerified,
      BadgeType.idVerified => DeelBadgeType.idVerified,
      BadgeType.trustedSeller => DeelBadgeType.topSeller,
      BadgeType.topRated => DeelBadgeType.topSeller,
      BadgeType.fastResponder => null,
      BadgeType.newUser => null,
    };
  }
}

/// Resolved visual configuration for a single badge type.
class DeelBadgeConfig {
  const DeelBadgeConfig({
    required this.icon,
    required this.labelKey,
    required this.tooltipKey,
    required this.colorResolver,
    required this.backgroundResolver,
  });

  final IconData icon;
  final String labelKey;
  final String tooltipKey;
  final Color Function(DeelBadgeThemeData theme) colorResolver;
  final Color Function(DeelBadgeThemeData theme) backgroundResolver;
}

/// Resolves visual config for each [DeelBadgeType].
DeelBadgeConfig resolveConfig(DeelBadgeType type) {
  return switch (type) {
    DeelBadgeType.emailVerified => DeelBadgeConfig(
      icon: PhosphorIcons.envelope(PhosphorIconsStyle.duotone),
      labelKey: 'badge.emailVerified',
      tooltipKey: 'badge.emailVerifiedTip',
      colorResolver: (t) => t.verified,
      backgroundResolver: (t) => t.verifiedBackground,
    ),
    DeelBadgeType.phoneVerified => DeelBadgeConfig(
      icon: PhosphorIcons.phone(PhosphorIconsStyle.duotone),
      labelKey: 'badge.phoneVerified',
      tooltipKey: 'badge.phoneVerifiedTip',
      colorResolver: (t) => t.verified,
      backgroundResolver: (t) => t.verifiedBackground,
    ),
    DeelBadgeType.idinVerified => DeelBadgeConfig(
      icon: PhosphorIcons.shieldCheck(PhosphorIconsStyle.duotone),
      labelKey: 'badge.idinVerified',
      tooltipKey: 'badge.idinVerifiedTip',
      colorResolver: (t) => t.verified,
      backgroundResolver: (t) => t.verifiedBackground,
    ),
    DeelBadgeType.idVerified => DeelBadgeConfig(
      icon: PhosphorIcons.identificationCard(PhosphorIconsStyle.duotone),
      labelKey: 'badge.idVerified',
      tooltipKey: 'badge.idVerifiedTip',
      colorResolver: (t) => t.verified,
      backgroundResolver: (t) => t.verifiedBackground,
    ),
    DeelBadgeType.businessSeller => DeelBadgeConfig(
      icon: PhosphorIcons.storefront(PhosphorIconsStyle.duotone),
      labelKey: 'badge.businessSeller',
      tooltipKey: 'badge.businessSellerTip',
      colorResolver: (t) => t.escrow,
      backgroundResolver: (t) => t.escrowBackground,
    ),
    DeelBadgeType.escrowProtected => DeelBadgeConfig(
      icon: PhosphorIcons.lock(PhosphorIconsStyle.duotone),
      labelKey: 'badge.escrowProtected',
      tooltipKey: 'badge.escrowProtectedTip',
      colorResolver: (t) => t.escrow,
      backgroundResolver: (t) => t.escrowBackground,
    ),
    DeelBadgeType.topSeller => DeelBadgeConfig(
      icon: PhosphorIcons.trophy(PhosphorIconsStyle.duotone),
      labelKey: 'badge.topSeller',
      tooltipKey: 'badge.topSellerTip',
      colorResolver: (t) => t.gold,
      backgroundResolver: (t) => t.goldBackground,
    ),
  };
}
