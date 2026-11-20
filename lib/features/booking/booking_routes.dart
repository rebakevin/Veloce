import 'package:go_router/go_router.dart';

import 'package:veloce/core/navigation/navigator_keys.dart';
import 'package:veloce/core/navigation/route_names.dart';

import 'presentation/pages/activity_page.dart';
import 'presentation/pages/agreement_page.dart';
import 'presentation/pages/booking_detail_page.dart';
import 'presentation/pages/decision_page.dart';
import 'presentation/pages/payment_page.dart';
import 'presentation/pages/payment_result_page.dart';

/// Tab root shown inside the role shell.
GoRoute renterActivityTab() => GoRoute(
  path: RouteNames.renterActivity,
  builder: (context, state) => const ActivityPage(),
);

/// Tab root shown inside the role shell.
GoRoute ownerActivityTab() => GoRoute(
  path: RouteNames.ownerActivity,
  builder: (context, state) => const ActivityPage(),
);

/// Full-screen routes of the booking feature, opened above the tab bar.
List<RouteBase> bookingRoutes() => [
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.bookingDecisionPattern,
    builder: (context, state) =>
        DecisionPage(bookingId: state.pathParameters['id']!),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.bookingPayPattern,
    builder: (context, state) =>
        PaymentPage(bookingId: state.pathParameters['id']!),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.bookingPayResultPattern,
    builder: (context, state) {
      final query = state.uri.queryParameters;
      return PaymentResultPage(
        bookingId: state.pathParameters['id']!,
        reference: query['reference'],
        bookingReference: query['booking'],
      );
    },
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.bookingAgreementPattern,
    builder: (context, state) =>
        AgreementPage(bookingId: state.pathParameters['id']!),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.ownerCarRequestsPattern,
    builder: (context, state) => ActivityPage(
      vehicleId: state.pathParameters['id']!,
      title: 'Requests',
      standalone: true,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.bookingPattern,
    builder: (context, state) =>
        BookingDetailPage(bookingId: state.pathParameters['id']!),
  ),
];
