import 'package:go_router/go_router.dart';

import 'package:veloce/core/navigation/navigator_keys.dart';
import 'package:veloce/core/navigation/route_names.dart';

import 'presentation/pages/owner_finances_page.dart';
import 'presentation/pages/owner_transactions_page.dart';
import 'presentation/pages/renter_payments_page.dart';

/// Full-screen routes of the finances feature, opened above the tab bar.
List<RouteBase> financesRoutes() => [
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.ownerFinances,
    builder: (context, state) => const OwnerFinancesPage(),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.ownerTransactions,
    builder: (context, state) => const OwnerTransactionsPage(),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.ownerCarFinancesPattern,
    builder: (context, state) =>
        OwnerFinancesPage(carId: state.pathParameters['carId']),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.ownerCarTransactionsPattern,
    builder: (context, state) =>
        OwnerTransactionsPage(carId: state.pathParameters['carId']),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.renterPayments,
    builder: (context, state) => const RenterPaymentsPage(),
  ),
];
