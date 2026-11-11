import 'package:go_router/go_router.dart';

import 'package:veloce/core/navigation/navigator_keys.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/navigation/seed_ids.dart';
import 'package:veloce/core/widgets/placeholder_link.dart';
import 'package:veloce/core/widgets/placeholder_page.dart';

import 'presentation/pages/booking_detail_page.dart';

/// Tab root shown inside the role shell.
GoRoute renterActivityTab() => GoRoute(
  path: RouteNames.renterActivity,
  builder: (context, state) => PlaceholderPage(
    title: 'My activity',
    route: RouteNames.renterActivity,
    phase: 4,
    links: [
      PlaceholderLink('Booking (sample)', RouteNames.booking(SeedIds.booking)),
      PlaceholderLink(
        'Pay now (sample)',
        RouteNames.bookingPay(SeedIds.booking),
      ),
      PlaceholderLink(
        'Open pickup check',
        RouteNames.bookingPickup(SeedIds.booking),
      ),
      PlaceholderLink(
        'Write review',
        RouteNames.bookingReview(SeedIds.booking),
      ),
    ],
  ),
);

/// Tab root shown inside the role shell.
GoRoute ownerActivityTab() => GoRoute(
  path: RouteNames.ownerActivity,
  builder: (context, state) => PlaceholderPage(
    title: 'My activity',
    route: RouteNames.ownerActivity,
    phase: 4,
    links: [
      PlaceholderLink('Booking (sample)', RouteNames.booking(SeedIds.booking)),
      PlaceholderLink(
        'View requests for a car',
        RouteNames.ownerCarRequests(SeedIds.car),
      ),
      PlaceholderLink(
        'Open pickup check',
        RouteNames.bookingPickup(SeedIds.booking),
      ),
      PlaceholderLink(
        'Open return check',
        RouteNames.bookingReturn(SeedIds.booking),
      ),
      PlaceholderLink('Open claim', RouteNames.bookingSettle(SeedIds.booking)),
      PlaceholderLink(
        'Write review',
        RouteNames.bookingReview(SeedIds.booking),
      ),
    ],
  ),
);

/// Full-screen routes of the booking feature, opened above the tab bar.
List<RouteBase> bookingRoutes() => [
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.bookingDecisionPattern,
    builder: (context, state) => PlaceholderPage(
      title: 'Booking request',
      route: RouteNames.bookingDecisionPattern,
      phase: 4,
      links: [
        PlaceholderLink('Renter profile', RouteNames.user(SeedIds.renter)),
        PlaceholderLink(
          'Approve or decline',
          RouteNames.booking(state.pathParameters['id']!),
        ),
      ],
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.bookingPayPattern,
    builder: (context, state) => PlaceholderPage(
      title: 'Payment',
      route: RouteNames.bookingPayPattern,
      phase: 4,
      links: [
        PlaceholderLink(
          'Pay (simulated)',
          RouteNames.bookingPayResult(state.pathParameters['id']!),
        ),
      ],
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.bookingPayResultPattern,
    builder: (context, state) => PlaceholderPage(
      title: 'Payment result',
      route: RouteNames.bookingPayResultPattern,
      phase: 4,
      links: [
        PlaceholderLink(
          'View booking',
          RouteNames.booking(state.pathParameters['id']!),
        ),
      ],
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
