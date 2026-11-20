import 'package:flutter/material.dart';

import 'package:veloce/core/domain/enums/vehicle_type.dart';
import 'package:veloce/core/theme/app_spacing.dart';

import '../../domain/entities/search_options.dart';

/// Home type chips: All + the three types in the mock.
class HomeTypeChips extends StatelessWidget {
  const HomeTypeChips({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final VehicleType? selected;
  final ValueChanged<VehicleType?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: selected == null,
            onSelected: (_) => onSelected(null),
          ),
          for (final type in SearchOptions.homeTypes) ...[
            const SizedBox(width: AppSpacing.sm),
            ChoiceChip(
              label: Text(type.label),
              selected: selected == type,
              onSelected: (_) => onSelected(type),
            ),
          ],
        ],
      ),
    );
  }
}
