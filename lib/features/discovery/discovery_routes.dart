import 'package:go_router/go_router.dart';

import 'package:veloce/core/navigation/navigator_keys.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/widgets/placeholder_page.dart';

/// Tab root shown inside the role shell.
GoRoute renterHomeTab() => GoRoute(
  path: RouteNames.renterHome,
  builder: (context, state) => const PlaceholderPage(
    title: 'Explore',
    route: RouteNames.renterHome,
    phase: 3,
  ),
);

/// Full-screen routes of the discovery feature, opened above the tab bar.
List<RouteBase> discoveryRoutes() => [
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.renterSearch,
    builder: (context, state) => const PlaceholderPage(
      title: 'Search',
      route: RouteNames.renterSearch,
      phase: 3,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.renterFilters,
    builder: (context, state) => const PlaceholderPage(
      title: 'Filters',
      route: RouteNames.renterFilters,
      phase: 3,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.renterResults,
    builder: (context, state) => const PlaceholderPage(
      title: 'Results',
      route: RouteNames.renterResults,
      phase: 3,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.carPattern,
    builder: (context, state) => const PlaceholderPage(
      title: 'Car detail',
      route: RouteNames.carPattern,
      phase: 3,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.carMediaPattern,
    builder: (context, state) => const PlaceholderPage(
      title: 'Car media',
      route: RouteNames.carMediaPattern,
      phase: 3,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.carBookPattern,
    builder: (context, state) => const PlaceholderPage(
      title: 'Review request',
      route: RouteNames.carBookPattern,
      phase: 3,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.bookingRequestedPattern,
    builder: (context, state) => const PlaceholderPage(
      title: 'Request sent',
      route: RouteNames.bookingRequestedPattern,
      phase: 3,
    ),
  ),
];
