// TODO(#133): File exceeds 200-line limit (221 lines). Extract sub-widgets.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
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
    this.onSupport,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onItemTap;
  // Fix #1.11: typed as AsyncCallback so callers can await signOut before
  // navigation. ListTile.onTap discards the future at the tap site (unavoidable
  // with the ListTile API), but the async body runs correctly to completion.
  final AsyncCallback onSignOut;

  /// Fired when the Support footer link is tapped.
  /// When null, the link is hidden (WCAG 4.1.2 — interactive elements must
  /// have a determinable purpose).
  final VoidCallback? onSupport;

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
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          _buildHeader(context),
          const SizedBox(height: Spacing.s4),
          Expanded(child: _buildNavItems()),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: DeelmarktColors.primary,
            ),
          ),
          const SizedBox(height: Spacing.s1),
          Text(
            'admin.sidebar.subtitle'.tr(),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: DeelmarktColors.neutral500),
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
        return _NavTile(
          icon: icon,
          label: key.tr(),
          selected: index == selectedIndex,
          onTap: () => onItemTap(index),
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.s4),
      child: Column(
        children: [
          const Divider(color: DeelmarktColors.neutral200),
          const SizedBox(height: Spacing.s2),
          if (onSupport != null) ...[
            _footerLink(
              context,
              PhosphorIconsRegular.question,
              'admin.sidebar.support'.tr(),
              onTap: onSupport!,
            ),
            const SizedBox(height: Spacing.s2),
          ],
          _footerLink(
            context,
            PhosphorIconsRegular.signOut,
            'admin.sidebar.sign_out'.tr(),
            onTap: onSignOut,
          ),
        ],
      ),
    );
  }

  Widget _footerLink(
    BuildContext context,
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
          onTap: onTap,
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
                    style: (selected
                            ? Theme.of(context).textTheme.labelLarge
                            : Theme.of(context).textTheme.bodyMedium)
                        ?.copyWith(color: fg),
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
}
