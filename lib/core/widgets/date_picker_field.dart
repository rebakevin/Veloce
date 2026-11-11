import 'package:flutter/material.dart';

import 'package:veloce/core/formatting/formatters.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

/// Read-only field that opens a date picker and shows [errorText] inline.
class DatePickerField extends StatelessWidget {
  const DatePickerField({
    required this.label,
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
    super.key,
    this.value,
    this.initialDate,
    this.errorText,
  });

  final String label;
  final DateTime? value;
  final DateTime firstDate;
  final DateTime lastDate;

  /// Where the picker opens when [value] is empty.
  final DateTime? initialDate;
  final ValueChanged<DateTime> onChanged;
  final String? errorText;

  Future<void> _pick(BuildContext context) async {
    final start = value ?? initialDate ?? lastDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: start.isBefore(firstDate) ? firstDate : start,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: label,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final date = value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          button: true,
          label: date == null ? label : '$label, ${Formatters.date(date)}',
          excludeSemantics: true,
          child: InkWell(
            onTap: () => _pick(context),
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: InputDecorator(
              decoration: InputDecoration(
                errorText: errorText,
                suffixIcon: const Icon(Icons.calendar_today_outlined),
              ),
              child: Text(
                date == null ? 'Choose a date' : Formatters.date(date),
                style: TextStyle(color: date == null ? colors.muted : null),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
