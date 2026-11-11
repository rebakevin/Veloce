import 'package:go_router/go_router.dart';

import 'package:veloce/core/navigation/navigator_keys.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/navigation/seed_ids.dart';
import 'package:veloce/core/widgets/placeholder_link.dart';
import 'package:veloce/core/widgets/placeholder_page.dart';

/// Full-screen routes of the vehicles feature, opened above the tab bar.
List<RouteBase> vehiclesRoutes() => [
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.ownerCars,
    builder: (context, state) => PlaceholderPage(
      title: 'My cars',
      route: RouteNames.ownerCars,
      phase: 2,
      links: [
        const PlaceholderLink('List a car', RouteNames.ownerCarNew),
        PlaceholderLink('Car card (sample)', RouteNames.ownerCar(SeedIds.car)),
      ],
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.ownerCarNew,
    builder: (context, state) => PlaceholderPage(
      title: 'List a car',
      route: RouteNames.ownerCarNew,
      phase: 2,
      links: [
        PlaceholderLink(
          'Publish car',
          RouteNames.ownerCarPublished(SeedIds.car),
        ),
      ],
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.ownerCarPattern,
    builder: (context, state) => PlaceholderPage(
      title: 'My car',
      route: RouteNames.ownerCarPattern,
      phase: 2,
      links: [
        PlaceholderLink(
          'View as renter',
          RouteNames.car(state.pathParameters['id']!),
        ),
        PlaceholderLink(
          'Edit listing',
          RouteNames.ownerCarEdit(state.pathParameters['id']!),
        ),
        PlaceholderLink(
          'Availability',
          RouteNames.ownerCarAvailability(state.pathParameters['id']!),
        ),
        PlaceholderLink(
          'Documents',
          RouteNames.ownerCarDocuments(state.pathParameters['id']!),
        ),
      ],
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.ownerCarPublishedPattern,
    builder: (context, state) => PlaceholderPage(
      title: 'Your car is live',
      route: RouteNames.ownerCarPublishedPattern,
      phase: 2,
      links: [
        PlaceholderLink(
          'View listing',
          RouteNames.car(state.pathParameters['id']!),
        ),
        const PlaceholderLink('Manage my cars', RouteNames.ownerCars),
      ],
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.ownerCarRequestsPattern,
    builder: (context, state) => PlaceholderPage(
      title: 'Requests',
      route: RouteNames.ownerCarRequestsPattern,
      phase: 4,
      links: [
        PlaceholderLink(
          'Request (sample)',
          RouteNames.bookingDecision(SeedIds.pendingBooking),
        ),
      ],
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
