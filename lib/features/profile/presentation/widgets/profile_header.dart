import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/profile/domain/entities/user_entity.dart';
import 'package:deelmarkt/widgets/badges/deel_avatar.dart';

/// Profile header with avatar, display name, and member-since date.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({required this.user, super.key});

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    final memberSince = '${user.createdAt.month}/${user.createdAt.year}';

    return Column(
      children: [
        DeelAvatar(
          displayName: user.displayName,
          imageUrl: user.avatarUrl,
          size: DeelAvatarSize.large,
          showEditOverlay: true,
          onEditTap: () {
            // Tracked: #53
          },
        ),
        const SizedBox(height: Spacing.s3),
        Text(
          user.displayName,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: Spacing.s1),
        Text(
          '${'profile.memberSince'.tr()} $memberSince',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
