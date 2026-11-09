import 'package:flutter/widgets.dart';

import 'package:veloce/core/widgets/slot_placeholder.dart';

/// Slot owned by Phase 6; replace `build`, keep the constructor.
class ReviewsPreviewSection extends StatelessWidget {
  const ReviewsPreviewSection({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context) =>
      const SlotPlaceholder(name: 'ReviewsPreviewSection', phase: 6);
}
