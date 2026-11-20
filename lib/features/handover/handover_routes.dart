import 'package:go_router/go_router.dart';
import 'package:veloce/core/domain/enums/checklist_kind.dart';
import 'package:veloce/core/navigation/navigator_keys.dart';
import 'package:veloce/core/navigation/route_names.dart';

import 'presentation/pages/caution_claim_page.dart';
import 'presentation/pages/caution_settlement_page.dart';
import 'presentation/pages/checklist_page.dart';
import 'presentation/pages/repair_expense_page.dart';

List<RouteBase> handoverRoutes() => [
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.bookingPickupPattern,
    builder: (context, state) => ChecklistPage(
      bookingId: state.pathParameters['id']!,
      kind: ChecklistKind.pickup,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.bookingReturnPattern,
    builder: (context, state) => ChecklistPage(
      bookingId: state.pathParameters['id']!,
      kind: ChecklistKind.returning,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.bookingSettlePattern,
    builder: (context, state) =>
        CautionSettlementPage(bookingId: state.pathParameters['id']!),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.bookingClaimPattern,
    builder: (context, state) =>
        CautionClaimPage(bookingId: state.pathParameters['id']!),
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: RouteNames.bookingRepairCostPattern,
    builder: (context, state) =>
        RepairExpensePage(bookingId: state.pathParameters['id']!),
  ),
];
