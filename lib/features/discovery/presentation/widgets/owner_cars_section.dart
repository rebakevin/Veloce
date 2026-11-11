import 'package:flutter/widgets.dart';

import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/navigation/seed_ids.dart';
import 'package:veloce/core/widgets/placeholder_link.dart';
import 'package:veloce/core/widgets/slot_placeholder.dart';

/// Slot owned by Phase 3; replace `build`, keep the constructor.
class OwnerCarsSection extends StatelessWidget {
  const OwnerCarsSection({required this.ownerId, super.key});

  final String ownerId;

  @override
  Widget build(BuildContext context) => SlotPlaceholder(
    name: 'OwnerCarsSection',
    phase: 3,
    links: [PlaceholderLink('Car card (sample)', RouteNames.car(SeedIds.car))],
  );
}
