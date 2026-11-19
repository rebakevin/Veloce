import 'package:go_router/go_router.dart';

import 'package:veloce/core/navigation/navigator_keys.dart';
import 'package:veloce/core/navigation/route_names.dart';

import 'domain/entities/booking_request_draft.dart';
import 'domain/entities/car_detail_args.dart';
import 'domain/entities/search_query.dart';
import 'domain/entities/vehicle_filters.dart';
import 'presentation/pages/booking_requested_page.dart';
import 'presentation/pages/booking_review_page.dart';
import 'presentation/pages/car_dates_page.dart';
import 'presentation/pages/car_detail_page.dart';
import 'presentation/pages/car_media_page.dart';
import 'presentation/pages/filters_page.dart';
import 'presentation/pages/renter_home_page.dart';
import 'presentation/pages/renter_search_page.dart';
import 'presentation/pages/results_page.dart';

/// Tab root shown inside the role shell.
GoRoute renterHomeTab() => GoRoute(
  path: RouteNames.renterHome,
  builder: (context, state) => const RenterHomePage(),
);

/// Full-screen routes of the discovery feature, opened above the tab bar.
List<RouteBase> discoveryRoutes() => [
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.renterSearch,
    builder: (context, state) => const RenterSearchPage(),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.renterFilters,
    builder: (context, state) => FiltersPage(
      initial: state.extra as VehicleFilters? ?? VehicleFilters.none,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.renterResults,
    builder: (context, state) =>
        ResultsPage(initialQuery: state.extra as SearchQuery?),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.carPattern,
    builder: (context, state) => CarDetailPage(
      vehicleId: state.pathParameters['id']!,
      dates: state.extra as CarDetailArgs?,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.carMediaPattern,
    builder: (context, state) =>
        CarMediaPage(vehicleId: state.pathParameters['id']!),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.carDatesPattern,
    builder: (context, state) => CarDatesPage(
      vehicleId: state.pathParameters['id']!,
      dates: state.extra as CarDetailArgs?,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.carBookPattern,
    builder: (context, state) => BookingReviewPage(
      vehicleId: state.pathParameters['id']!,
      draft: state.extra as BookingRequestDraft?,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.bookingRequestedPattern,
    builder: (context, state) =>
        BookingRequestedPage(bookingId: state.pathParameters['id']!),
  ),
];
