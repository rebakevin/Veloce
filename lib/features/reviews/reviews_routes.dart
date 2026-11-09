import 'package:go_router/go_router.dart';

import 'package:veloce/core/navigation/navigator_keys.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/widgets/placeholder_page.dart';

/// Full-screen routes of the reviews feature, opened above the tab bar.
List<RouteBase> reviewsRoutes() => [
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.bookingReviewPattern,
    builder: (context, state) => const PlaceholderPage(
      title: 'Reviews',
      route: RouteNames.bookingReviewPattern,
      phase: 6,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.carReviewsPattern,
    builder: (context, state) => const PlaceholderPage(
      title: 'Car reviews',
      route: RouteNames.carReviewsPattern,
      phase: 6,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.userReviewsPattern,
    builder: (context, state) => const PlaceholderPage(
      title: 'Reviews received',
      route: RouteNames.userReviewsPattern,
      phase: 6,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.profileReviews,
    builder: (context, state) => const PlaceholderPage(
      title: 'My reviews',
      route: RouteNames.profileReviews,
      phase: 6,
    ),
  ),
];
