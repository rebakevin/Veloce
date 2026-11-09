import 'package:flutter/material.dart';

import '../formatting/formatters.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Read-only field that opens a date-range picker. Days before [firstDate]
/// (default today) are disabled.
class DateRangeField extends StatelessWidget {
  const DateRangeField({
    required this.label,
    required this.onChanged,
    super.key,
    this.value,
    this.firstDate,
    this.lastDate,
    this.errorText,
  });

  final String label;
  final DateTimeRange? value;
  final ValueChanged<DateTimeRange> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final range = value;
    final text = range == null
        ? 'Choose dates'
        : Formatters.dateRange(range.start, range.end);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: AppSpacing.sm),
        InkWell(
          onTap: () => _pick(context),
          child: InputDecorator(
            decoration: InputDecoration(
              errorText: errorText,
              suffixIcon: const Icon(Icons.calendar_month_outlined),
            ),
            child: Text(text),
          ),
        ),
      ],
    );
  }

  Future<void> _pick(BuildContext context) async {
    final today = DateTime.now();
    final start = firstDate ?? DateTime(today.year, today.month, today.day);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: start,
      lastDate: lastDate ?? start.add(const Duration(days: 365)),
      initialDateRange: value,
    );
    if (picked != null) onChanged(picked);
  }
}
