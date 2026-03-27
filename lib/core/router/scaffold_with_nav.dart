import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../design_system/breakpoints.dart';
import '../design_system/colors.dart';

/// Shared navigation item data — single source of truth for both bar and rail.
class _NavItem {
  const _NavItem({required this.iconData, required this.labelKey});

  final PhosphorIconData Function([PhosphorIconsStyle]) iconData;
  final String labelKey;

  Icon _icon({bool selected = false}) => Icon(
    selected ? iconData(PhosphorIconsStyle.bold) : iconData(),
    color: selected ? DeelmarktColors.primary : DeelmarktColors.neutral500,
    semanticLabel: labelKey.tr(),
  );

  NavigationDestination toBarDestination() => NavigationDestination(
    icon: _icon(),
    selectedIcon: _icon(selected: true),
    label: labelKey.tr(),
  );

  NavigationRailDestination toRailDestination() => NavigationRailDestination(
    icon: _icon(),
    selectedIcon: _icon(selected: true),
    label: Text(labelKey.tr()),
  );
}

const _navItems = [
  _NavItem(iconData: PhosphorIcons.house, labelKey: 'nav.home'),
  _NavItem(iconData: PhosphorIcons.magnifyingGlass, labelKey: 'nav.search'),
  _NavItem(iconData: PhosphorIcons.plusCircle, labelKey: 'nav.sell'),
  _NavItem(iconData: PhosphorIcons.chatCircle, labelKey: 'nav.messages'),
  _NavItem(iconData: PhosphorIcons.user, labelKey: 'nav.profile'),
];

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
              destinations:
                  _navItems.map((item) => item.toRailDestination()).toList(),
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
        destinations: _navItems.map((item) => item.toBarDestination()).toList(),
      ),
    );
  }
}
