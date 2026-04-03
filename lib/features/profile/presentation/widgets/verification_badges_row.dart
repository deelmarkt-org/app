import 'package:flutter/material.dart';

import 'package:deelmarkt/features/profile/domain/entities/user_entity.dart';
import 'package:deelmarkt/widgets/badges/deel_badge.dart';
import 'package:deelmarkt/widgets/badges/deel_badge_data.dart';

/// Displays the user's verification badges as a row.
///
/// Maps domain [BadgeType] to presentation [DeelBadgeType],
/// filtering out types without visual representation.
class VerificationBadgesRow extends StatelessWidget {
  const VerificationBadgesRow({required this.badges, super.key});

  final List<BadgeType> badges;

  @override
  Widget build(BuildContext context) {
    final visualBadges =
        badges
            .map(DeelBadgeType.fromBadgeType)
            .whereType<DeelBadgeType>()
            .toList();

    if (visualBadges.isEmpty) return const SizedBox.shrink();

    return DeelBadgeRow(badges: visualBadges);
  }
}
