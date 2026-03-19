import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../design_system/colors.dart';

/// Bottom navigation scaffold — wraps the shell routes.
/// Extracted to its own file per CLAUDE.md §1.1 (shared UI component).
class ScaffoldWithNav extends StatelessWidget {
  const ScaffoldWithNav({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: [
          NavigationDestination(
            icon: Icon(
              PhosphorIcons.house(),
              color: DeelmarktColors.neutral500,
              semanticLabel: 'nav.home'.tr(),
            ),
            selectedIcon: Icon(
              PhosphorIcons.house(PhosphorIconsStyle.bold),
              color: DeelmarktColors.primary,
              semanticLabel: 'nav.home'.tr(),
            ),
            label: 'nav.home'.tr(),
          ),
          NavigationDestination(
            icon: Icon(
              PhosphorIcons.magnifyingGlass(),
              color: DeelmarktColors.neutral500,
              semanticLabel: 'nav.search'.tr(),
            ),
            selectedIcon: Icon(
              PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.bold),
              color: DeelmarktColors.primary,
              semanticLabel: 'nav.search'.tr(),
            ),
            label: 'nav.search'.tr(),
          ),
          NavigationDestination(
            icon: Icon(
              PhosphorIcons.plusCircle(),
              color: DeelmarktColors.neutral500,
              semanticLabel: 'nav.sell'.tr(),
            ),
            selectedIcon: Icon(
              PhosphorIcons.plusCircle(PhosphorIconsStyle.bold),
              color: DeelmarktColors.primary,
              semanticLabel: 'nav.sell'.tr(),
            ),
            label: 'nav.sell'.tr(),
          ),
          NavigationDestination(
            icon: Icon(
              PhosphorIcons.chatCircle(),
              color: DeelmarktColors.neutral500,
              semanticLabel: 'nav.messages'.tr(),
            ),
            selectedIcon: Icon(
              PhosphorIcons.chatCircle(PhosphorIconsStyle.bold),
              color: DeelmarktColors.primary,
              semanticLabel: 'nav.messages'.tr(),
            ),
            label: 'nav.messages'.tr(),
          ),
          NavigationDestination(
            icon: Icon(
              PhosphorIcons.user(),
              color: DeelmarktColors.neutral500,
              semanticLabel: 'nav.profile'.tr(),
            ),
            selectedIcon: Icon(
              PhosphorIcons.user(PhosphorIconsStyle.bold),
              color: DeelmarktColors.primary,
              semanticLabel: 'nav.profile'.tr(),
            ),
            label: 'nav.profile'.tr(),
          ),
        ],
      ),
    );
  }
}
