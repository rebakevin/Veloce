import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// One bottom-navigation tab of a role shell.
class ShellDestination {
  const ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Bottom-navigation scaffold shared by the renter and owner shells.
class RoleShell extends StatelessWidget {
  const RoleShell({
    required this.navigationShell,
    required this.destinations,
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final List<ShellDestination> destinations;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          for (final destination in destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: destination.label,
            ),
        ],
      ),
    );
  }
}
