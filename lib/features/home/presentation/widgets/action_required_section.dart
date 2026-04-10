import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/home/domain/entities/action_item_entity.dart';
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
          child: SectionHeader(title: 'home.seller.actionRequired'.tr()),
        ),
        ...actions.map(
          (action) =>
              _ActionTile(action: action, onTap: () => onActionTap(action)),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action, required this.onTap});

  final ActionItemEntity action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? DeelmarktColors.darkSurface : DeelmarktColors.neutral50;

    final isShip = action.type == ActionItemType.shipOrder;
    final title =
        isShip
            ? 'home.seller.shipOrderTitle'.tr(
              args: [action.referenceId.substring(0, 4)],
            )
            : 'home.seller.replyTo'.tr(
              namedArgs: {'name': action.otherUserName ?? ''},
            );
    final subtitle =
        isShip
            ? 'home.seller.shipOrderSubtitle'.tr()
            : 'home.seller.unreadCount'.tr(
              args: [(action.unreadCount ?? 0).toString()],
            );

    return Semantics(
      button: true,
      label: title,
      child: Padding(
        padding: const EdgeInsets.only(
          left: Spacing.s4,
          right: Spacing.s4,
          bottom: Spacing.s3,
        ),
        child: Material(
          color: bgColor,
          borderRadius: BorderRadius.circular(DeelmarktRadius.xl),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(DeelmarktRadius.xl),
            child: Container(
              constraints: const BoxConstraints(minHeight: 72),
              padding: const EdgeInsets.all(Spacing.s4),
              child: Row(
                children: [
                  _icon(),
                  const SizedBox(width: Spacing.s3),
                  _content(context, isDark, title, subtitle),
                  const SizedBox(width: Spacing.s2),
                  _chevron(isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _icon() {
    final isShip = action.type == ActionItemType.shipOrder;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color:
            isShip
                ? DeelmarktColors.primarySurface
                : DeelmarktColors.secondarySurface,
        borderRadius: BorderRadius.circular(DeelmarktRadius.lg),
      ),
      child: Icon(
        isShip
            ? PhosphorIcons.package(PhosphorIconsStyle.fill)
            : PhosphorIcons.chatCircle(PhosphorIconsStyle.fill),
        size: 24,
        color: isShip ? DeelmarktColors.primary : DeelmarktColors.secondary,
      ),
    );
  }

  Widget _content(
    BuildContext context,
    bool isDark,
    String title,
    String subtitle,
  ) {
    final subtitleColor =
        isDark
            ? DeelmarktColors.darkOnSurfaceSecondary
            : DeelmarktColors.neutral500;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: Spacing.s1),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: subtitleColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _chevron(bool isDark) {
    return Icon(
      PhosphorIcons.caretRight(),
      size: 20,
      color:
          isDark
              ? DeelmarktColors.darkOnSurfaceSecondary
              : DeelmarktColors.neutral500,
    );
  }
}
