import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:deelmarkt/core/router/routes.dart';
import 'package:deelmarkt/core/services/app_logger.dart';
import 'package:deelmarkt/core/services/supabase_service.dart';
import 'package:deelmarkt/features/admin/presentation/widgets/admin_narrow_viewport_message.dart';
import 'package:deelmarkt/features/admin/presentation/widgets/admin_sidebar.dart';

/// Shell screen for the admin panel — 240px sidebar + content area.
///
/// Uses [AdminSidebar] for navigation and renders the active child
/// route in the remaining space. On viewports narrower than
/// [_minDesktopWidth] a [AdminNarrowViewportMessage] is shown instead.
///
/// Reference: docs/screens/08-admin/01-admin-panel.md
class AdminShellScreen extends ConsumerWidget {
  const AdminShellScreen({required this.child, super.key});

  /// The currently active admin child route.
  final Widget child;

  /// Minimum viewport width for the admin panel.
  /// Raised from 768 to 900 (issue #196) to align with the app's expanded
  /// breakpoint (840) plus the 240px sidebar — narrower viewports cannot
  /// render the two-column layout comfortably.
  static const double _minDesktopWidth = 900.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < _minDesktopWidth) {
            return const AdminNarrowViewportMessage();
          }
          return Scaffold(
            body: Row(
              children: [
                AdminSidebar(
                  selectedIndex: _selectedIndex(context),
                  onItemTap: (index) => _onTap(context, index),
                  // Fix #1.11: await signOut before navigation — prevents a race
                  // window where the user navigates while the session is still active.
                  // Error is caught + logged; navigation proceeds regardless so admin
                  // is not left stranded on a broken session.
                  onSignOut: () async {
                    try {
                      await ref.read(supabaseClientProvider).auth.signOut();
                    } on Object catch (e, st) {
                      AppLogger.error(
                        'Admin signOut failed',
                        error: e,
                        stackTrace: st,
                        tag: 'admin',
                      );
                    }
                    if (context.mounted) context.go(AppRoutes.login);
                  },
                  onSupport:
                      () => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('admin.comingSoon'.tr())),
                      ),
                ),
                Expanded(child: child),
              ],
            ),
          );
        },
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
