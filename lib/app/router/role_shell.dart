import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:veloce/app/router/main_bar.dart';
import 'package:veloce/app/router/shell_action.dart';
import 'package:veloce/app/router/shell_destination.dart';

import 'package:veloce/core/navigation/route_names.dart';

/// Bottom bar shared by the renter and owner shells, as in the mock: a side
/// action, three tabs and the notifications bell.
class RoleShell extends StatelessWidget {
  const RoleShell({
    required this.navigationShell,
    required this.destinations,
    required this.sideAction,
    required this.notificationsRoute,
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final List<ShellDestination> destinations;
  final ShellAction sideAction;
  final String notificationsRoute;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      floatingActionButton: kDebugMode
          ? FloatingActionButton.small(
              tooltip: 'All routes (debug)',
              onPressed: () => context.push(RouteNames.devRoutes),
              child: const Icon(Icons.map_outlined),
            )
          : null,
      bottomNavigationBar: MainBar(
        destinations: destinations,
        selectedIndex: navigationShell.currentIndex,
        onSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        sideAction: sideAction,
        onSide: () => context.push(sideAction.route),
        onNotifications: () => context.push(notificationsRoute),
      ),
    );
  }
}
