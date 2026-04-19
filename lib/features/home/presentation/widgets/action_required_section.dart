import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/router/routes.dart';
import 'package:deelmarkt/features/home/domain/entities/action_item_entity.dart';
import 'package:deelmarkt/features/home/presentation/widgets/action_tile.dart';
import 'package:deelmarkt/features/home/presentation/widgets/section_header.dart';

/// "Actie vereist" section with orange-bordered action tiles.
///
/// Each tile shows an icon, title, subtitle, and a chevron.
/// Tap navigates to the relevant screen (shipping QR or chat).
///
/// Reference: docs/screens/02-home/designs/seller_mode_home_mobile_light/
class ActionRequiredSection extends StatelessWidget {
  const ActionRequiredSection({
    required this.actions,
    required this.onActionTap,
    super.key,
  });

  final List<ActionItemEntity> actions;
  final ValueChanged<ActionItemEntity> onActionTap;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: Spacing.s3),
          child: SectionHeader(
            title: 'home.seller.actionRequired'.tr(),
            actionLabel: 'home.viewAll'.tr(),
            onAction: () => context.go(AppRoutes.messages),
          ),
        ),
        ...actions.map(
          (action) =>
              ActionTile(action: action, onTap: () => onActionTap(action)),
        ),
      ],
    );
  }
}
