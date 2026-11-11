import 'package:go_router/go_router.dart';

import 'package:veloce/core/navigation/navigator_keys.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/navigation/seed_ids.dart';
import 'package:veloce/core/widgets/placeholder_link.dart';
import 'package:veloce/core/widgets/placeholder_page.dart';

/// Tab root shown inside the role shell.
GoRoute renterHomeTab() => GoRoute(
  path: RouteNames.renterHome,
  builder: (context, state) => PlaceholderPage(
    title: 'Home',
    route: RouteNames.renterHome,
    phase: 3,
    links: [
      const PlaceholderLink('Search cars', RouteNames.renterResults),
      const PlaceholderLink('Pickup and return dates', RouteNames.renterSearch),
      PlaceholderLink('Car card (sample)', RouteNames.car(SeedIds.car)),
    ],
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
    builder: (context, state) => PlaceholderPage(
      title: 'Results',
      route: RouteNames.renterResults,
      phase: 3,
      links: [
        const PlaceholderLink(
          'Pickup and return dates',
          RouteNames.renterSearch,
        ),
        const PlaceholderLink('Filters', RouteNames.renterFilters),
        PlaceholderLink('Car card (sample)', RouteNames.car(SeedIds.car)),
      ],
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.carPattern,
    builder: (context, state) => PlaceholderPage(
      title: 'Car detail',
      route: RouteNames.carPattern,
      phase: 3,
      links: [
        PlaceholderLink(
          'Photos and video',
          RouteNames.carMedia(state.pathParameters['id']!),
        ),
        PlaceholderLink(
          'Change dates',
          RouteNames.carDates(state.pathParameters['id']!),
        ),
        PlaceholderLink('Owner profile', RouteNames.user(SeedIds.owner)),
        PlaceholderLink(
          'Car reviews',
          RouteNames.carReviews(state.pathParameters['id']!),
        ),
        PlaceholderLink(
          'Request to book',
          RouteNames.carBook(state.pathParameters['id']!),
        ),
      ],
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
    path: RouteNames.carDatesPattern,
    builder: (context, state) => const PlaceholderPage(
      title: 'Select dates',
      route: RouteNames.carDatesPattern,
      phase: 3,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.carBookPattern,
    builder: (context, state) => PlaceholderPage(
      title: 'Review request',
      route: RouteNames.carBookPattern,
      phase: 3,
      links: [
        PlaceholderLink('View owner profile', RouteNames.user(SeedIds.owner)),
        PlaceholderLink(
          'Send booking request',
          RouteNames.bookingRequested(SeedIds.pendingBooking),
        ),
      ],
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.bookingRequestedPattern,
    builder: (context, state) => const PlaceholderPage(
      title: 'Request sent',
      route: RouteNames.bookingRequestedPattern,
      phase: 3,
      links: [
        PlaceholderLink(
          'View request in My Activity',
          RouteNames.renterActivity,
          isTab: true,
        ),
        PlaceholderLink(
          'Keep exploring cars',
          RouteNames.renterHome,
          isTab: true,
        ),
      ],
    ),
  ),
];
