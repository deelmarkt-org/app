import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../design_system/breakpoints.dart';
import '../design_system/colors.dart';

/// Adaptive navigation scaffold — bottom nav on mobile, side rail on desktop.
///
/// Breakpoint behaviour (per docs/design-system/tokens.md):
///   - compact (<600px): bottom NavigationBar
///   - medium (600-840px): bottom NavigationBar
///   - expanded (≥840px): side NavigationRail
///
/// Extracted to its own file per CLAUDE.md §1.1 (shared UI component).
class ScaffoldWithNav extends StatelessWidget {
  const ScaffoldWithNav({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final useRail = Breakpoints.isExpanded(context);

    if (useRail) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              backgroundColor:
                  Theme.of(context).brightness == Brightness.dark
                      ? DeelmarktColors.darkSurface
                      : DeelmarktColors.white,
              indicatorColor:
                  Theme.of(context).brightness == Brightness.dark
                      ? DeelmarktColors.darkSurfaceElevated
                      : DeelmarktColors.primarySurface,
              destinations: _railDestinations,
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: _barDestinations,
      ),
    );
  }
}

final _barDestinations = [
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
];

final _railDestinations = [
  NavigationRailDestination(
    icon: Icon(PhosphorIcons.house(), color: DeelmarktColors.neutral500),
    selectedIcon: Icon(
      PhosphorIcons.house(PhosphorIconsStyle.bold),
      color: DeelmarktColors.primary,
    ),
    label: Text('nav.home'.tr()),
  ),
  NavigationRailDestination(
    icon: Icon(
      PhosphorIcons.magnifyingGlass(),
      color: DeelmarktColors.neutral500,
    ),
    selectedIcon: Icon(
      PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.bold),
      color: DeelmarktColors.primary,
    ),
    label: Text('nav.search'.tr()),
  ),
  NavigationRailDestination(
    icon: Icon(PhosphorIcons.plusCircle(), color: DeelmarktColors.neutral500),
    selectedIcon: Icon(
      PhosphorIcons.plusCircle(PhosphorIconsStyle.bold),
      color: DeelmarktColors.primary,
    ),
    label: Text('nav.sell'.tr()),
  ),
  NavigationRailDestination(
    icon: Icon(PhosphorIcons.chatCircle(), color: DeelmarktColors.neutral500),
    selectedIcon: Icon(
      PhosphorIcons.chatCircle(PhosphorIconsStyle.bold),
      color: DeelmarktColors.primary,
    ),
    label: Text('nav.messages'.tr()),
  ),
  NavigationRailDestination(
    icon: Icon(PhosphorIcons.user(), color: DeelmarktColors.neutral500),
    selectedIcon: Icon(
      PhosphorIcons.user(PhosphorIconsStyle.bold),
      color: DeelmarktColors.primary,
    ),
    label: Text('nav.profile'.tr()),
  ),
];
