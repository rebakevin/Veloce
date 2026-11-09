import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:veloce/app/owner_home/owner_home_page.dart';
import 'package:veloce/app/router/role_shell.dart';
import 'package:veloce/app/router/router_refresh_listenable.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/navigation/auth_redirect.dart';
import 'package:veloce/core/navigation/navigator_keys.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/features/auth/auth.dart';
import 'package:veloce/features/booking/booking.dart';
import 'package:veloce/features/discovery/discovery.dart';
import 'package:veloce/features/finances/finances.dart';
import 'package:veloce/features/handover/handover.dart';
import 'package:veloce/features/notifications/notifications.dart';
import 'package:veloce/features/profile/profile.dart';
import 'package:veloce/features/reviews/reviews.dart';
import 'package:veloce/features/vehicles/vehicles.dart';

const List<ShellDestination> _renterDestinations = [
  ShellDestination(
    label: 'Explore',
    icon: Icons.search,
    selectedIcon: Icons.search,
  ),
  ShellDestination(
    label: 'Activity',
    icon: Icons.event_note_outlined,
    selectedIcon: Icons.event_note,
  ),
  ShellDestination(
    label: 'Alerts',
    icon: Icons.notifications_outlined,
    selectedIcon: Icons.notifications,
  ),
  ShellDestination(
    label: 'Profile',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
  ),
];

const List<ShellDestination> _ownerDestinations = [
  ShellDestination(
    label: 'Home',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
  ),
  ShellDestination(
    label: 'Cars',
    icon: Icons.directions_car_outlined,
    selectedIcon: Icons.directions_car,
  ),
  ShellDestination(
    label: 'Activity',
    icon: Icons.event_note_outlined,
    selectedIcon: Icons.event_note,
  ),
  ShellDestination(
    label: 'Alerts',
    icon: Icons.notifications_outlined,
    selectedIcon: Icons.notifications,
  ),
  ShellDestination(
    label: 'Profile',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
  ),
];

/// Composes every feature's routes into the app's [GoRouter] (TECHNICAL.md §10).
GoRouter createAppRouter(AuthSession session) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RouteNames.splash,
    refreshListenable: RouterRefreshListenable(session.changes),
    redirect: (context, state) => authRedirect(
      userId: session.currentUserId,
      role: session.role,
      location: state.matchedLocation,
    ),
    routes: [
      ...authRoutes(),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => RoleShell(
          navigationShell: shell,
          destinations: _renterDestinations,
        ),
        branches: [
          StatefulShellBranch(routes: [renterHomeTab()]),
          StatefulShellBranch(routes: [renterActivityTab()]),
          StatefulShellBranch(routes: [renterNotificationsTab()]),
          StatefulShellBranch(routes: [renterProfileTab()]),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            RoleShell(navigationShell: shell, destinations: _ownerDestinations),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.ownerHome,
                builder: (context, state) => const OwnerHomePage(),
              ),
            ],
          ),
          StatefulShellBranch(routes: [ownerCarsTab()]),
          StatefulShellBranch(routes: [ownerActivityTab()]),
          StatefulShellBranch(routes: [ownerNotificationsTab()]),
          StatefulShellBranch(routes: [ownerProfileTab()]),
        ],
      ),
      ...profileRoutes(),
      ...vehiclesRoutes(),
      ...discoveryRoutes(),
      ...bookingRoutes(),
      ...handoverRoutes(),
      ...financesRoutes(),
      ...reviewsRoutes(),
    ],
  );
}
