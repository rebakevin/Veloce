import 'package:flutter/material.dart';
import 'package:veloce/core/domain/enums/fuel_type.dart';
import 'package:veloce/core/domain/enums/transmission.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

import '../../domain/entities/wizard_draft.dart';
import '../../domain/rules/wizard_step_rules.dart';
import 'draft_text_field.dart';

class SpecsStep extends StatelessWidget {
  const SpecsStep({
    required this.draft,
    required this.errors,
    required this.onChanged,
    super.key,
  });

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
        const Text('Transmission', style: AppTextStyles.caption),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<Transmission>(
          initialValue: draft.transmission,
          decoration: InputDecoration(
            hintText: 'Choose the transmission',
            errorText: errors[WizardField.transmission],
          ),
          items: [
            for (final value in Transmission.values)
              DropdownMenuItem(value: value, child: Text(value.label)),
          ],
          onChanged: (value) {
            if (value != null) onChanged(draft.copyWith(transmission: value));
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        const Text('Fuel type', style: AppTextStyles.caption),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<FuelType>(
          initialValue: draft.fuel,
          decoration: InputDecoration(
            hintText: 'Choose the fuel type',
            errorText: errors[WizardField.fuel],
          ),
          items: [
            for (final value in FuelType.values)
              DropdownMenuItem(value: value, child: Text(value.label)),
          ],
          onChanged: (value) {
            if (value != null) onChanged(draft.copyWith(fuel: value));
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        DraftTextField(
          label: 'Seats',
          hint: '5',
          initialValue: draft.seats?.toString() ?? '',
          errorText: errors[WizardField.seats],
          keyboardType: TextInputType.number,
          onChanged: (value) =>
              onChanged(draft.copyWith(seats: parseWhole(value))),
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