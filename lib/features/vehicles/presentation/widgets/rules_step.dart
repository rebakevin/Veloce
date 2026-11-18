import 'package:flutter/material.dart';
import 'package:veloce/core/theme/app_spacing.dart';

import '../../domain/entities/wizard_draft.dart';
import '../../domain/rules/wizard_step_rules.dart';
import 'draft_text_field.dart';

class RulesStep extends StatelessWidget {
  const RulesStep({
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
          label: 'Fuel rule',
          hint: 'Return the car with the same fuel level',
          initialValue: draft.fuelRule,
          errorText: errors[WizardField.fuelRule],
          onChanged: (value) => onChanged(draft.copyWith(fuelRule: value)),
        ),
        const SizedBox(height: AppSpacing.lg),
        DraftTextField(
          label: 'Smoking',
          hint: 'No smoking in the car',
          initialValue: draft.smoking,
          errorText: errors[WizardField.smoking],
          onChanged: (value) => onChanged(draft.copyWith(smoking: value)),
        ),
      ],
    );
  }
}