import 'package:go_router/go_router.dart';

import 'package:veloce/core/navigation/navigator_keys.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/widgets/placeholder_page.dart';

/// Full-screen routes of the handover feature, opened above the tab bar.
List<RouteBase> handoverRoutes() => [
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.bookingPickupPattern,
    builder: (context, state) => const PlaceholderPage(
      title: 'Pickup checklist',
      route: RouteNames.bookingPickupPattern,
      phase: 5,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.bookingReturnPattern,
    builder: (context, state) => const PlaceholderPage(
      title: 'Return checklist',
      route: RouteNames.bookingReturnPattern,
      phase: 5,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.bookingSettlePattern,
    builder: (context, state) => const PlaceholderPage(
      title: 'Settle caution',
      route: RouteNames.bookingSettlePattern,
      phase: 5,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.bookingClaimPattern,
    builder: (context, state) => const PlaceholderPage(
      title: 'Caution claim',
      route: RouteNames.bookingClaimPattern,
      phase: 5,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.bookingRepairCostPattern,
    builder: (context, state) => const PlaceholderPage(
      title: 'Repair cost',
      route: RouteNames.bookingRepairCostPattern,
      phase: 5,
    ),
  ),
];
