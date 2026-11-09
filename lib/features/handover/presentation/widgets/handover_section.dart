import 'package:flutter/widgets.dart';

import 'package:veloce/core/widgets/slot_placeholder.dart';

/// Slot owned by Phase 5; replace `build`, keep the constructor.
class HandoverSection extends StatelessWidget {
  const HandoverSection({required this.bookingId, super.key});

  final String bookingId;

  @override
  Widget build(BuildContext context) =>
      const SlotPlaceholder(name: 'HandoverSection', phase: 5);
}
