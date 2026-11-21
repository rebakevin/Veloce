import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

import '../../domain/entities/search_options.dart';
import '../bloc/search_state.dart';

/// Area and dates form shared by the home search card and `/renter/search`.
class RenterSearchForm extends StatelessWidget {
  const RenterSearchForm({
    required this.state,
    required this.onAreaChanged,
    required this.onDatesChanged,
    super.key,
  });

  final SearchState state;
  final ValueChanged<String?> onAreaChanged;
  final void Function(DateTime start, DateTime end) onDatesChanged;

  Future<void> _pick(BuildContext context, DateTimeRange? current) async {
    final today = GetIt.I<Clock>().now();
    final firstDate = DateTime(today.year, today.month, today.day);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: firstDate.add(const Duration(days: 365)),
      initialDateRange: current,
    );
    if (picked != null) onDatesChanged(picked.start, picked.end);
  }

  @override
  Widget build(BuildContext context) {
    final start = state.start;
    final end = state.end;
    final dates = start == null || end == null
        ? null
        : DateTimeRange(start: start, end: end);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AreaField(value: state.area, onChanged: onAreaChanged),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _DateTile(
                label: 'Pickup',
                date: start,
                onTap: () => _pick(context, dates),
              ),
            ),
            const SizedBox(width: AppSpacing.sm + 2),
            Expanded(
              child: _DateTile(
                label: 'Return',
                date: end,
                onTap: () => _pick(context, dates),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.date,
    required this.onTap,
  });

  static final DateFormat _format = DateFormat('EEE d MMM');

  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final date = this.date;
    return Semantics(
      button: true,
      label: '$label date',
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: colors.line, width: 1.5),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          onTap: onTap,
          child: SizedBox(
            height: 60,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md + 2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.label.copyWith(color: colors.muted),
                  ),
                  Text(
                    date == null ? 'Choose' : _format.format(date),
                    style: AppTextStyles.button.copyWith(color: colors.ink),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AreaField extends StatelessWidget {
  const _AreaField({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value ?? SearchOptions.anywhere;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pickup area in Kigali',
          style: AppTextStyles.caption.copyWith(
            color: context.colors.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm - 2),
        InputDecorator(
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: selected,
              style: AppTextStyles.bodyLarge.copyWith(
                color: context.colors.ink,
                fontWeight: FontWeight.w600,
              ),
              items: [
                for (final area in [
                  SearchOptions.anywhere,
                  ...SearchOptions.neighbourhoods,
                ])
                  DropdownMenuItem(value: area, child: Text(area)),
              ],
              onChanged: (area) => onChanged(
                area == null || area == SearchOptions.anywhere ? null : area,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
