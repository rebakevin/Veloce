import 'package:flutter/widgets.dart';

import 'package:veloce/core/widgets/slot_placeholder.dart';

/// Slot owned by Phase 6; replace `build`, keep the constructor.
class FinancesCard extends StatelessWidget {
  const FinancesCard({super.key});

  @override
  Widget build(BuildContext context) =>
      const SlotPlaceholder(name: 'FinancesCard', phase: 6);
}
