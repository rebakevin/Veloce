import 'package:go_router/go_router.dart';

import 'package:veloce/core/navigation/navigator_keys.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/navigation/seed_ids.dart';
import 'package:veloce/core/widgets/placeholder_link.dart';
import 'package:veloce/core/widgets/placeholder_page.dart';

/// Opened from the bell in the bottom bar, above the tab bar.
List<RouteBase> notificationsRoutes() => [
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.renterNotifications,
    builder: (context, state) => PlaceholderPage(
      title: 'Notifications',
      route: RouteNames.renterNotifications,
      phase: 6,
      links: [
        PlaceholderLink(
          'Open a notification (sample)',
          RouteNames.booking(SeedIds.booking),
        ),
      ],
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.ownerNotifications,
    builder: (context, state) => PlaceholderPage(
      title: 'Notifications',
      route: RouteNames.ownerNotifications,
      phase: 6,
      links: [
        PlaceholderLink(
          'Open a notification (sample)',
          RouteNames.booking(SeedIds.booking),
        ),
      ],
    ),
  ),
];
