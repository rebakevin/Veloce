import 'package:flutter/widgets.dart';

import 'package:veloce/core/widgets/slot_placeholder.dart';

/// Slot owned by Phase 6; replace `build`, keep the constructor.
class PostRentalSection extends StatelessWidget {
  const PostRentalSection({required this.bookingId, super.key});

  final String bookingId;

  @override
  Widget build(BuildContext context) =>
      const SlotPlaceholder(name: 'PostRentalSection', phase: 6);
}
