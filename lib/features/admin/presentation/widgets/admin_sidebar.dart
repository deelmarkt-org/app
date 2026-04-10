import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';

/// 240px-wide admin sidebar: ModerationHub branding, 6 nav items,
/// and footer links (Support · Sign Out).
/// Reference: docs/screens/08-admin/01-admin-panel.md
class AdminSidebar extends StatelessWidget {
  const AdminSidebar({
    required this.selectedIndex,
    required this.onItemTap,
    required this.onSignOut,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onItemTap;

  /// Fired when the Sign Out footer link is tapped.
  final VoidCallback onSignOut;

  static const double _width = 240;

  static const _items = <(IconData, String)>[
    (PhosphorIconsRegular.squaresFour, 'admin.nav.dashboard'),
    (PhosphorIconsRegular.flag, 'admin.nav.flagged'),
    (PhosphorIconsRegular.userMinus, 'admin.nav.reported'),
    (PhosphorIconsRegular.scales, 'admin.nav.disputes'),
    (PhosphorIconsRegular.shieldCheck, 'admin.nav.dsa'),
    (PhosphorIconsRegular.arrowCounterClockwise, 'admin.nav.appeals'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _width,
      color: DeelmarktColors.white,
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: Spacing.s4),
          Expanded(child: _buildNavItems()),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.s4,
        Spacing.s6,
        Spacing.s4,
        Spacing.s2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admin.sidebar.title'.tr(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: DeelmarktColors.primary,
            ),
          ),
          const SizedBox(height: Spacing.s1),
          Text(
            'admin.sidebar.subtitle'.tr(),
            style: const TextStyle(
              fontSize: 12,
              color: DeelmarktColors.neutral500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItems() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.s2),
      itemCount: _items.length,
      separatorBuilder: (_, _) => const SizedBox(height: Spacing.s1),
      itemBuilder: (_, index) {
        final (icon, key) = _items[index];
        return _navTile(icon, key.tr(), index == selectedIndex, index);
      },
    );
  }

  Widget _navTile(IconData icon, String label, bool selected, int index) {
    final bg = selected ? DeelmarktColors.primarySurface : Colors.transparent;
    final fg = selected ? DeelmarktColors.primary : DeelmarktColors.neutral700;
    final radius = BorderRadius.circular(DeelmarktRadius.sm);

    return Semantics(
      label: label,
      button: true,
      selected: selected,
      child: Material(
        color: bg,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: () => onItemTap(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.s3,
              vertical: Spacing.s2,
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: fg),
                const SizedBox(width: Spacing.s3),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: fg,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(Spacing.s4),
      child: Column(
        children: [
          const Divider(color: DeelmarktColors.neutral200),
          const SizedBox(height: Spacing.s2),
          _footerLink(
            PhosphorIconsRegular.question,
            'admin.sidebar.support'.tr(),
            onTap: () {},
          ),
          const SizedBox(height: Spacing.s2),
          _footerLink(
            PhosphorIconsRegular.signOut,
            'admin.sidebar.sign_out'.tr(),
            onTap: onSignOut,
          ),
        ],
      ),
    );
  }

  Widget _footerLink(
    IconData icon,
    String label, {
    required VoidCallback onTap,
  }) {
    return Semantics(
      label: label,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(DeelmarktRadius.sm),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.s3,
            vertical: Spacing.s2,
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: DeelmarktColors.neutral500),
              const SizedBox(width: Spacing.s3),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: DeelmarktColors.neutral500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
