import 'package:flutter/widgets.dart';

import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/widgets/placeholder_link.dart';
import 'package:veloce/core/widgets/slot_placeholder.dart';

/// Slot owned by Phase 2; replace `build`, keep the constructor.
class CarCountCard extends StatelessWidget {
  const CarCountCard({super.key});

  @override
  Widget build(BuildContext context) => const SlotPlaceholder(
    name: 'CarCountCard',
    phase: 2,
    links: [PlaceholderLink('Published cars', RouteNames.ownerCars)],
  );
}
