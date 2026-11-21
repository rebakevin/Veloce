import 'package:flutter/material.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

import '../../domain/entities/wizard_draft.dart';
import '../../domain/rules/wizard_step_rules.dart';
import 'draft_text_field.dart';
import 'rules_pdf_picker.dart';

class RulesStep extends StatelessWidget {
  const RulesStep({
    required this.draft,
    required this.errors,
    required this.onChanged,
    super.key,
    this.pdfPicker = const FilePickerRulesPdfPicker(),
  });

  final WizardDraft draft;
  final Map<WizardField, String> errors;
  final ValueChanged<WizardDraft> onChanged;
  final RulesPdfPicker pdfPicker;

  Future<void> _pickPdf(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final pdf = await pdfPicker.pick();
    if (pdf == null) return;
    if (pdf.isTooLarge) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('That PDF is over 5 MB. Pick a smaller one.'),
        ),
      );
      return;
    }
    onChanged(draft.copyWith(rulesPdf: pdf, clearExistingRules: true));
  }

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
        const SizedBox(height: AppSpacing.lg),
        DraftTextField(
          label: 'Extras (optional)',
          hint: 'Child seat, phone charger',
          initialValue: draft.extras.join(', '),
          onChanged: (value) => onChanged(
            draft.copyWith(
              extras: [
                for (final extra in value.split(','))
                  if (extra.trim().isNotEmpty) extra.trim(),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const Text('Rental rules PDF (optional)', style: AppTextStyles.caption),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () => _pickPdf(context),
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: Text(
            draft.rulesPdf == null && draft.existingRulesUrl == null
                ? 'Add a PDF (max 5 MB)'
                : 'Replace PDF',
          ),
        ),
        if (draft.rulesPdf != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(draft.rulesPdf!.name),
          )
        else if (draft.existingRulesUrl != null)
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.sm),
            child: Text('This car already has a rules PDF.'),
          ),
        if (draft.rulesPdf != null || draft.existingRulesUrl != null)
          TextButton(
            onPressed: () => onChanged(
              draft.copyWith(clearRulesPdf: true, clearExistingRules: true),
            ),
            child: const Text('Remove PDF'),
          ),
      ],
    );
  }
}
