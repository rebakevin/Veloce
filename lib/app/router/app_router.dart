import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:veloce/app/owner_home/owner_home_page.dart';
import 'package:veloce/app/router/role_shell.dart';
import 'package:veloce/app/router/router_refresh_listenable.dart';
import 'package:veloce/app/router/shell_action.dart';
import 'package:veloce/app/router/shell_destination.dart';
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

/// The three tabs both roles share, as in the mock.
const List<ShellDestination> _destinations = [
  ShellDestination(
    label: 'Home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
  ),
  ShellDestination(
    label: 'My Activity',
    icon: Icons.event_note_outlined,
    selectedIcon: Icons.event_note,
  ),
  ShellDestination(
    label: 'Profile',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
  ),
];

const ShellAction _renterSideAction = ShellAction(
  label: 'Search cars',
  icon: Icons.search,
  route: RouteNames.renterResults,
);

const ShellAction _ownerSideAction = ShellAction(
  label: 'My cars',
  icon: Icons.directions_car_outlined,
  route: RouteNames.ownerCars,
);

/// Composes every feature's routes into the app's [GoRouter] (TECHNICAL.md §10).
GoRouter createAppRouter(AuthSession session, {String? initialLocation}) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    // Debug builds open the seeded-account picker until Phase 1 adds real login.
    initialLocation:
        initialLocation ??
        (kDebugMode ? RouteNames.devLogin : RouteNames.splash),
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
          destinations: _destinations,
          sideAction: _renterSideAction,
          notificationsRoute: RouteNames.renterNotifications,
        ),
        branches: [
          StatefulShellBranch(routes: [renterHomeTab()]),
          StatefulShellBranch(routes: [renterActivityTab()]),
          StatefulShellBranch(routes: [renterProfileTab()]),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => RoleShell(
          navigationShell: shell,
          destinations: _destinations,
          sideAction: _ownerSideAction,
          notificationsRoute: RouteNames.ownerNotifications,
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.ownerHome,
                builder: (context, state) => const OwnerHomePage(),
              ),
            ],
          ),
          StatefulShellBranch(routes: [ownerActivityTab()]),
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
      ...notificationsRoutes(),
    ],
  );
}
