import 'package:flutter/widgets.dart';

import 'package:veloce/core/widgets/slot_placeholder.dart';

/// Slot owned by Phase 3; replace `build`, keep the constructor.
class OwnerCarsSection extends StatelessWidget {
  const OwnerCarsSection({required this.ownerId, super.key});

  final String ownerId;

  @override
  Widget build(BuildContext context) =>
      const SlotPlaceholder(name: 'OwnerCarsSection', phase: 3);
}
