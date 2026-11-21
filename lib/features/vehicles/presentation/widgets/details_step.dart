import 'package:flutter/material.dart';
import 'package:veloce/core/domain/enums/vehicle_type.dart';
import 'package:veloce/core/theme/app_spacing.dart';

import '../../domain/entities/wizard_draft.dart';
import '../../domain/rules/wizard_step_rules.dart';
import 'choice_chips.dart';
import 'draft_text_field.dart';

class DetailsStep extends StatelessWidget {
  const DetailsStep({
    required this.draft,
    required this.errors,
    required this.onChanged,
    super.key,
  });

  static const List<String> _neighbourhoods = [
    'Kacyiru',
    'Nyarutarama',
    'Kimironko',
    'Remera',
    'Kicukiro',
    'Nyamirambo',
    'Gisozi',
    'Kimihurura',
    'Kibagabaga',
    'Kabeza',
  ];

  final WizardDraft draft;
  final Map<WizardField, String> errors;
  final ValueChanged<WizardDraft> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DraftTextField(
          label: draft.isEditing
              ? 'Number plate (fixed, it matches your documents)'
              : 'Number plate',
          hint: 'RAB 123 A',
          enabled: !draft.isEditing,
          initialValue: draft.plate,
          errorText: errors[WizardField.plate],
          onChanged: (value) => onChanged(draft.copyWith(plate: value)),
        ),
        const SizedBox(height: AppSpacing.lg),
        DraftTextField(
          label: 'Make',
          hint: 'Toyota',
          initialValue: draft.make,
          errorText: errors[WizardField.make],
          onChanged: (value) => onChanged(draft.copyWith(make: value)),
        ),
        const SizedBox(height: AppSpacing.lg),
        DraftTextField(
          label: 'Model',
          hint: 'RAV4',
          initialValue: draft.model,
          errorText: errors[WizardField.model],
          onChanged: (value) => onChanged(draft.copyWith(model: value)),
        ),
        const SizedBox(height: AppSpacing.lg),
        DraftTextField(
          label: 'Year',
          hint: '2020',
          initialValue: draft.year?.toString() ?? '',
          errorText: errors[WizardField.year],
          keyboardType: TextInputType.number,
          onChanged: (value) =>
              onChanged(draft.copyWith(year: parseWhole(value))),
        ),
        const SizedBox(height: AppSpacing.lg),
        ChoiceChipGroup<VehicleType>(
          label: 'Vehicle type',
          options: VehicleType.values,
          selected: draft.type,
          labelOf: (type) => type.label,
          errorText: errors[WizardField.type],
          onSelected: (type) => onChanged(draft.copyWith(type: type)),
        ),
        const SizedBox(height: AppSpacing.lg),
        DraftTextField(
          label: 'Description (optional)',
          hint: 'Anything renters should know',
          initialValue: draft.description,
          errorText: errors[WizardField.description],
          maxLines: 3,
          onChanged: (value) => onChanged(draft.copyWith(description: value)),
        ),
        const SizedBox(height: AppSpacing.lg),
        ChoiceChipGroup<String>(
          label: 'Pickup neighbourhood',
          options: [
            ..._neighbourhoods,
            if (draft.neighbourhood.isNotEmpty &&
                !_neighbourhoods.contains(draft.neighbourhood))
              draft.neighbourhood,
          ],
          selected: draft.neighbourhood,
          labelOf: (name) => name,
          errorText: errors[WizardField.neighbourhood],
          onSelected: (name) => onChanged(draft.copyWith(neighbourhood: name)),
        ),
      ],
    );
  }
}
