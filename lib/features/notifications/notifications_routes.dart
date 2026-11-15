import 'package:go_router/go_router.dart';

import 'package:veloce/core/navigation/navigator_keys.dart';
import 'package:veloce/core/navigation/route_names.dart';

import 'presentation/pages/notifications_page.dart';

/// Opened from the bell in the bottom bar, above the tab bar.
List<RouteBase> notificationsRoutes() => [
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.renterNotifications,
    builder: (context, state) => const NotificationsPage(),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.ownerNotifications,
    builder: (context, state) => const NotificationsPage(),
  ),
];
