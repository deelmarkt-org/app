import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:deelmarkt/core/router/routes.dart';
import 'package:deelmarkt/features/admin/presentation/widgets/admin_sidebar.dart';

/// Shell screen for the admin panel — 240px sidebar + content area.
///
/// Uses [AdminSidebar] for navigation and renders the active child
/// route in the remaining space.
///
/// Reference: docs/screens/08-admin/01-admin-panel.md
class AdminShellScreen extends StatelessWidget {
  const AdminShellScreen({required this.child, super.key});

  /// The currently active admin child route.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AdminSidebar(
            selectedIndex: _selectedIndex(context),
            onItemTap: (index) => _onTap(context, index),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(AppRoutes.adminFlaggedListings)) return 1;
    if (location.startsWith(AppRoutes.adminReportedUsers)) return 2;
    if (location.startsWith(AppRoutes.adminDisputes)) return 3;
    if (location.startsWith(AppRoutes.adminDsaNotices)) return 4;
    if (location.startsWith(AppRoutes.adminAppeals)) return 5;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    final route = switch (index) {
      1 => AppRoutes.adminFlaggedListings,
      2 => AppRoutes.adminReportedUsers,
      3 => AppRoutes.adminDisputes,
      4 => AppRoutes.adminDsaNotices,
      5 => AppRoutes.adminAppeals,
      _ => AppRoutes.admin,
    };
    context.go(route);
  }
}
