import 'package:flutter/material.dart';
import 'package:veloce/core/domain/enums/vehicle_type.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

import '../../domain/entities/wizard_draft.dart';
import '../../domain/rules/wizard_step_rules.dart';
import 'draft_text_field.dart';

class DetailsStep extends StatelessWidget {
  const DetailsStep({
    required this.draft,
    required this.errors,
    required this.onChanged,
    super.key,
  });

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
        const Text('Car type', style: AppTextStyles.caption),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<VehicleType>(
          initialValue: draft.type,
          decoration: InputDecoration(
            hintText: 'Choose a type',
            errorText: errors[WizardField.type],
          ),
          items: [
            for (final type in VehicleType.values)
              DropdownMenuItem(value: type, child: Text(type.label)),
          ],
          onChanged: (value) {
            if (value != null) onChanged(draft.copyWith(type: value));
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        DraftTextField(
          label: 'Pickup neighbourhood',
          hint: 'Kimironko',
          initialValue: draft.neighbourhood,
          errorText: errors[WizardField.neighbourhood],
          onChanged: (value) => onChanged(draft.copyWith(neighbourhood: value)),
        ),
        const SizedBox(height: AppSpacing.lg),
        DraftTextField(
          label: 'Description',
          hint: 'Tell renters what makes this car a good pick',
          initialValue: draft.description,
          errorText: errors[WizardField.description],
          maxLines: 3,
          onChanged: (value) => onChanged(draft.copyWith(description: value)),
        ),
      ],
    );
  }
}
