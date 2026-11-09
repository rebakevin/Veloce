import 'package:go_router/go_router.dart';

import 'package:veloce/core/navigation/navigator_keys.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/widgets/placeholder_page.dart';

import 'presentation/pages/booking_detail_page.dart';

/// Tab root shown inside the role shell.
GoRoute renterActivityTab() => GoRoute(
  path: RouteNames.renterActivity,
  builder: (context, state) => const PlaceholderPage(
    title: 'My activity',
    route: RouteNames.renterActivity,
    phase: 4,
  ),
);

/// Tab root shown inside the role shell.
GoRoute ownerActivityTab() => GoRoute(
  path: RouteNames.ownerActivity,
  builder: (context, state) => const PlaceholderPage(
    title: 'My activity',
    route: RouteNames.ownerActivity,
    phase: 4,
  ),
);

/// Full-screen routes of the booking feature, opened above the tab bar.
List<RouteBase> bookingRoutes() => [
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.bookingDecisionPattern,
    builder: (context, state) => const PlaceholderPage(
      title: 'Booking request',
      route: RouteNames.bookingDecisionPattern,
      phase: 4,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.bookingPayPattern,
    builder: (context, state) => const PlaceholderPage(
      title: 'Payment',
      route: RouteNames.bookingPayPattern,
      phase: 4,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.bookingPayResultPattern,
    builder: (context, state) => const PlaceholderPage(
      title: 'Payment result',
      route: RouteNames.bookingPayResultPattern,
      phase: 4,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.bookingAgreementPattern,
    builder: (context, state) => const PlaceholderPage(
      title: 'Rental agreement',
      route: RouteNames.bookingAgreementPattern,
      phase: 4,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.bookingPattern,
    builder: (context, state) =>
        BookingDetailPage(bookingId: state.pathParameters['id']!),
  ),
];
