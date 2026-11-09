import 'package:go_router/go_router.dart';

import 'package:veloce/core/navigation/navigator_keys.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/widgets/placeholder_page.dart';

/// Tab root shown inside the role shell.
GoRoute ownerCarsTab() => GoRoute(
  path: RouteNames.ownerCars,
  builder: (context, state) => const PlaceholderPage(
    title: 'My cars',
    route: RouteNames.ownerCars,
    phase: 2,
  ),
);

/// Full-screen routes of the vehicles feature, opened above the tab bar.
List<RouteBase> vehiclesRoutes() => [
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.ownerCarNew,
    builder: (context, state) => const PlaceholderPage(
      title: 'List a car',
      route: RouteNames.ownerCarNew,
      phase: 2,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.ownerCarEditPattern,
    builder: (context, state) => const PlaceholderPage(
      title: 'Edit car',
      route: RouteNames.ownerCarEditPattern,
      phase: 2,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.ownerCarAvailabilityPattern,
    builder: (context, state) => const PlaceholderPage(
      title: 'Availability',
      route: RouteNames.ownerCarAvailabilityPattern,
      phase: 2,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.ownerCarDocumentsPattern,
    builder: (context, state) => const PlaceholderPage(
      title: 'Car documents',
      route: RouteNames.ownerCarDocumentsPattern,
      phase: 2,
    ),
  ),
];
