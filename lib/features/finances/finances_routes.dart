import 'package:go_router/go_router.dart';

import 'package:veloce/core/navigation/navigator_keys.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/widgets/placeholder_page.dart';

/// Full-screen routes of the finances feature, opened above the tab bar.
List<RouteBase> financesRoutes() => [
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.ownerFinances,
    builder: (context, state) => const PlaceholderPage(
      title: 'Finances',
      route: RouteNames.ownerFinances,
      phase: 6,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.ownerTransactions,
    builder: (context, state) => const PlaceholderPage(
      title: 'All transactions',
      route: RouteNames.ownerTransactions,
      phase: 6,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.ownerCarFinancesPattern,
    builder: (context, state) => const PlaceholderPage(
      title: 'Car finances',
      route: RouteNames.ownerCarFinancesPattern,
      phase: 6,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.ownerCarTransactionsPattern,
    builder: (context, state) => const PlaceholderPage(
      title: 'Car transactions',
      route: RouteNames.ownerCarTransactionsPattern,
      phase: 6,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.renterPayments,
    builder: (context, state) => const PlaceholderPage(
      title: 'Payment history',
      route: RouteNames.renterPayments,
      phase: 6,
    ),
  ),
];
