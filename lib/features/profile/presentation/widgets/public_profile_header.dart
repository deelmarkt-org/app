import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/utils/time_ago.dart';
import 'package:deelmarkt/features/profile/domain/entities/review_aggregate.dart';
import 'package:deelmarkt/features/profile/domain/entities/user_entity.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/profile_stats_row.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/rating_display.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/verification_badges_row.dart';
import 'package:deelmarkt/widgets/badges/deel_avatar.dart';

/// Public profile header: avatar, name, member-since, badges, rating, stats.
///
/// Unlike [ProfileHeader], no edit overlay — read-only for public view.
class PublicProfileHeader extends StatelessWidget {
  const PublicProfileHeader({
    required this.user,
    required this.aggregate,
    super.key,
  });

  final UserEntity user;
  final AsyncValue<ReviewAggregate> aggregate;

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;
    final dateFormatted = formatMemberSince(user.createdAt, locale: locale);
    final memberSince = 'sellerProfile.memberSince'.tr(
      namedArgs: {'date': dateFormatted},
    );

    return Column(
      children: [
        DeelAvatar(
          displayName: user.displayName,
          imageUrl: user.avatarUrl,
          size: DeelAvatarSize.large,
        ),
        const SizedBox(height: Spacing.s3),
        Text(
          user.displayName,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: Spacing.s1),
        Text(
          memberSince,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.s3),
        VerificationBadgesRow(badges: user.badges),
        const SizedBox(height: Spacing.s3),
        _buildRating(context),
        const SizedBox(height: Spacing.s4),
        ProfileStatsRow(user: user),
      ],
    );
  }

  Widget _buildRating(BuildContext context) {
    return aggregate.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (agg) => RatingDisplay.fromAggregate(agg),
    );
  }
}
