import 'package:go_router/go_router.dart';

import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/widgets/placeholder_page.dart';

/// Tab root shown inside the role shell.
GoRoute renterNotificationsTab() => GoRoute(
  path: RouteNames.renterNotifications,
  builder: (context, state) => const PlaceholderPage(
    title: 'Notifications',
    route: RouteNames.renterNotifications,
    phase: 6,
  ),
);

/// Tab root shown inside the role shell.
GoRoute ownerNotificationsTab() => GoRoute(
  path: RouteNames.ownerNotifications,
  builder: (context, state) => const PlaceholderPage(
    title: 'Notifications',
    route: RouteNames.ownerNotifications,
    phase: 6,
  ),
);
