import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/widgets/date_range_field.dart';

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

  @override
  Widget build(BuildContext context) {
    final today = GetIt.I<Clock>().now();
    final firstDate = DateTime(today.year, today.month, today.day);
    final dates = state.start == null || state.end == null
        ? null
        : DateTimeRange(start: state.start!, end: state.end!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AreaField(value: state.area, onChanged: onAreaChanged),
        const SizedBox(height: AppSpacing.md),
        DateRangeField(
          label: 'Pickup and return dates',
          value: dates,
          firstDate: firstDate,
          lastDate: firstDate.add(const Duration(days: 365)),
          onChanged: (range) => onDatesChanged(range.start, range.end),
        ),
      ],
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
        const Text('Where are you going?'),
        const SizedBox(height: AppSpacing.sm),
        InputDecorator(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.place_outlined),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: selected,
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
