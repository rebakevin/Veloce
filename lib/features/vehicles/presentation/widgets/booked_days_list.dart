import 'package:flutter/material.dart';
import 'package:veloce/core/formatting/formatters.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

import '../../domain/entities/day_range.dart';

/// Booked periods, shown as locked: they must stay inside the available range.
class BookedDaysList extends StatelessWidget {
  const BookedDaysList({required this.days, super.key});

  final List<DayRange> days;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (days.isEmpty) {
      return const Text(
        'No booked days. You can change your dates freely.',
        style: AppTextStyles.bodySmall,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final range in days)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Icon(Icons.lock_outline, size: 18, color: colors.muted),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    Formatters.dateRange(range.start, range.end),
                    style: AppTextStyles.body,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
