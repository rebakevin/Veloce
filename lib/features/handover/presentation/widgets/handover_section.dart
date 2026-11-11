import 'package:flutter/widgets.dart';

import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/widgets/placeholder_link.dart';
import 'package:veloce/core/widgets/slot_placeholder.dart';

/// Slot owned by Phase 5; replace `build`, keep the constructor.
class HandoverSection extends StatelessWidget {
  const HandoverSection({required this.bookingId, super.key});

  final String bookingId;

  @override
  Widget build(BuildContext context) => SlotPlaceholder(
    name: 'HandoverSection',
    phase: 5,
    links: [
      PlaceholderLink('Open pickup check', RouteNames.bookingPickup(bookingId)),
      PlaceholderLink('Open return check', RouteNames.bookingReturn(bookingId)),
      PlaceholderLink(
        'Settle caution (owner)',
        RouteNames.bookingSettle(bookingId),
      ),
      PlaceholderLink(
        'Open claim (renter)',
        RouteNames.bookingClaim(bookingId),
      ),
      PlaceholderLink(
        'Log repair cost (owner)',
        RouteNames.bookingRepairCost(bookingId),
      ),
    ],
  );
}
