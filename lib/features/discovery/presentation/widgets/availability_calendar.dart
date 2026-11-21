import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/formatting/formatters.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

import '../../domain/entities/vehicle_detail.dart';
import '../../domain/services/availability_rules.dart';

/// Availability window, blocked days and a range picker that cannot select a
/// blocked day or a day outside the owner's window.
class AvailabilityCalendar extends StatelessWidget {
  const AvailabilityCalendar({
    required this.detail,
    required this.start,
    required this.end,
    required this.onChanged,
    super.key,
    this.rules = const AvailabilityRules(),
  });

  final VehicleDetail detail;
  final DateTime? start;
  final DateTime? end;
  final void Function(DateTime start, DateTime end) onChanged;
  final AvailabilityRules rules;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final vehicle = detail.vehicle;
    final from = vehicle.availableFrom;
    final to = vehicle.availableTo;
    final blocked = [
      for (final block in detail.blocks)
        if (to == null || block.startDate.isBefore(to)) block,
    ];
    final today = rules.day(GetIt.I<Clock>().now());
    final first = from == null
        ? today
        : (rules.day(from).isBefore(today) ? today : rules.day(from));
    final last = to == null ? today : rules.day(to);
    final canPick = from != null && to != null && !last.isBefore(first);
    final range = start == null || end == null
        ? null
        : DateTimeRange(start: start!, end: end!);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Availability', style: AppTextStyles.cardTitle),
            const SizedBox(height: AppSpacing.sm),
            Text(
              from == null || to == null
                  ? 'This car is not open for requests.'
                  : 'Bookable ${Formatters.date(from)} – '
                        '${Formatters.date(to)}',
              style: AppTextStyles.bodySmall.copyWith(color: colors.muted),
            ),
            if (blocked.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Unavailable: ${blocked.map((b) => '${Formatters.date(b.startDate)} – ${Formatters.date(b.endDate)}').join(', ')}',
                style: AppTextStyles.caption.copyWith(color: colors.danger),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            if (!canPick)
              Text(
                'Choose other dates from the car page.',
                style: AppTextStyles.caption.copyWith(color: colors.muted),
              )
            else
              _RangePicker(
                first: first,
                last: last,
                value: range,
                selectable: (day, start, end) => _selectable(
                  day,
                  first,
                  last,
                  isReturnDay: start != null && end == null,
                ),
                onChanged: onChanged,
              ),
            if (blocked.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final block in blocked)
                    Chip(
                      avatar: Icon(
                        Icons.block_outlined,
                        size: 16,
                        color: colors.danger,
                      ),
                      label: Text(
                        '${Formatters.date(block.startDate)} – '
                        '${Formatters.date(block.endDate)}',
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// A pickup day needs the night after it free; a return day needs the night
  /// before it free, so a return on the day another booking starts is allowed.
  bool _selectable(
    DateTime day,
    DateTime first,
    DateTime last, {
    required bool isReturnDay,
  }) {
    final value = rules.day(day);
    if (value.isBefore(first) || value.isAfter(last)) return false;
    final night = isReturnDay ? value.subtract(const Duration(days: 1)) : value;
    return detail.blocks.every(
      (block) => !rules.blockOverlaps(
        block,
        night,
        night.add(const Duration(days: 1)),
      ),
    );
  }
}

class _RangePicker extends StatelessWidget {
  const _RangePicker({
    required this.first,
    required this.last,
    required this.value,
    required this.selectable,
    required this.onChanged,
  });

  final DateTime first;
  final DateTime last;
  final DateTimeRange? value;
  final bool Function(DateTime day, DateTime? start, DateTime? end) selectable;
  final void Function(DateTime start, DateTime end) onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final range = value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pickup and return dates', style: AppTextStyles.caption),
        const SizedBox(height: AppSpacing.sm),
        InkWell(
          onTap: () => _pick(context),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InputDecorator(
            decoration: const InputDecoration(
              suffixIcon: Icon(Icons.calendar_month_outlined),
            ),
            child: Text(
              range == null
                  ? 'Choose dates'
                  : Formatters.dateRange(range.start, range.end),
              style: TextStyle(color: range == null ? colors.muted : null),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pick(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: first,
      lastDate: last,
      initialDateRange: value,
      selectableDayPredicate: selectable,
      helpText: 'Pickup and return dates',
    );
    if (picked != null) onChanged(picked.start, picked.end);
  }
}
