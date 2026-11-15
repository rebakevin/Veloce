import 'package:go_router/go_router.dart';

import 'package:veloce/core/navigation/navigator_keys.dart';
import 'package:veloce/core/navigation/route_names.dart';

import 'presentation/pages/booking_review_page.dart';
import 'presentation/pages/car_reviews_page.dart';
import 'presentation/pages/profile_reviews_page.dart';
import 'presentation/pages/user_reviews_page.dart';

List<RouteBase> reviewsRoutes() => [
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.bookingReviewPattern,
    builder: (context, state) =>
        BookingReviewPage(bookingId: state.pathParameters['id']!),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.carReviewsPattern,
    builder: (context, state) =>
        CarReviewsPage(carId: state.pathParameters['id']!),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.userReviewsPattern,
    builder: (context, state) =>
        UserReviewsPage(userId: state.pathParameters['id']!),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.profileReviews,
    builder: (context, state) => const ProfileReviewsPage(),
  ),
];
