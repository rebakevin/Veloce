import 'package:flutter/material.dart';

import 'package:veloce/core/formatting/formatters.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

import '../../domain/entities/vehicle_detail.dart';

/// The short "3+ days: RWF 80,000 per day" note from SPECS §5.3.
class LongRentalNote extends StatelessWidget {
  const LongRentalNote({required this.detail, super.key});

  final VehicleDetail detail;

  @override
  Widget build(BuildContext context) {
    final rates = [...detail.vehicle.longRates]
      ..sort((a, b) => a.fromDays.compareTo(b.fromDays));
    if (rates.isEmpty) return const SizedBox.shrink();
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.brandWash,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Long-rental prices', style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.xs),
            for (final rate in rates)
              Text(
                '${rate.fromDays}+ days: '
                '${Formatters.rwf(rate.pricePerDay)} per day',
                style: AppTextStyles.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}
