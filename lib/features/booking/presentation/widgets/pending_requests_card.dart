import 'package:flutter/widgets.dart';

import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/widgets/placeholder_link.dart';
import 'package:veloce/core/widgets/slot_placeholder.dart';

/// Slot owned by Phase 4; replace `build`, keep the constructor.
class PendingRequestsCard extends StatelessWidget {
  const PendingRequestsCard({super.key});

  @override
  Widget build(BuildContext context) => const SlotPlaceholder(
    name: 'PendingRequestsCard',
    phase: 4,
    links: [
      PlaceholderLink(
        'Needs your decision',
        RouteNames.ownerActivity,
        isTab: true,
      ),
    ],
  );
}
