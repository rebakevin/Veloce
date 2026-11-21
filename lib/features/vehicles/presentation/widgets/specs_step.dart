import 'package:flutter/material.dart';
import 'package:veloce/core/domain/enums/fuel_type.dart';
import 'package:veloce/core/domain/enums/transmission.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

import '../../domain/entities/wizard_draft.dart';
import '../../domain/rules/wizard_step_rules.dart';
import 'choice_chips.dart';

class SpecsStep extends StatelessWidget {
  const SpecsStep({
    required this.draft,
    required this.errors,
    required this.onChanged,
    super.key,
  });

  static const List<int> _seatOptions = [2, 4, 5, 7, 8];

  static const List<String> _features = [
    'Air conditioning',
    'Bluetooth',
    'USB charging',
    'GPS',
    'Child seat',
    'Backup camera',
  ];

  final WizardDraft draft;
  final Map<WizardField, String> errors;
  final ValueChanged<WizardDraft> onChanged;

  void _toggle(String feature, {required bool on}) {
    final features = on
        ? [...draft.features, feature]
        : draft.features.where((item) => item != feature).toList();
    onChanged(draft.copyWith(features: features));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChoiceChipGroup<Transmission>(
          label: 'Transmission',
          options: Transmission.values,
          selected: draft.transmission,
          labelOf: (value) => value.label,
          errorText: errors[WizardField.transmission],
          onSelected: (value) => onChanged(draft.copyWith(transmission: value)),
        ),
        const SizedBox(height: AppSpacing.lg),
        ChoiceChipGroup<FuelType>(
          label: 'Fuel type',
          options: FuelType.values,
          selected: draft.fuel,
          labelOf: (value) => value.label,
          errorText: errors[WizardField.fuel],
          onSelected: (value) => onChanged(draft.copyWith(fuel: value)),
        ),
        const SizedBox(height: AppSpacing.lg),
        ChoiceChipGroup<int>(
          label: 'Seats',
          options: [
            ..._seatOptions,
            if (draft.seats != null && !_seatOptions.contains(draft.seats))
              draft.seats!,
          ],
          selected: draft.seats,
          labelOf: (value) => '$value',
          errorText: errors[WizardField.seats],
          onSelected: (value) => onChanged(draft.copyWith(seats: value)),
        ),
        const SizedBox(height: AppSpacing.lg),
        const Text('Features', style: AppTextStyles.caption),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final feature in _features)
              FilterChip(
                label: Text(feature),
                selected: draft.features.contains(feature),
                onSelected: (on) => _toggle(feature, on: on),
              ),
          ],
        ),
      ],
    );
  }
}
