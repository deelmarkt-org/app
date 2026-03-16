import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, semanticLabel: 'Home'),
            label: 'Home', // l10n: P-task
          ),
          NavigationDestination(
            icon: Icon(Icons.search, semanticLabel: 'Search'),
            label: 'Search', // l10n: P-task
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline, semanticLabel: 'Sell'),
            label: 'Sell', // l10n: P-task
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline, semanticLabel: 'Messages'),
            label: 'Messages', // l10n: P-task
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, semanticLabel: 'Profile'),
            label: 'Profile', // l10n: P-task
          ),
        ],
      ),
    );
  }
}
