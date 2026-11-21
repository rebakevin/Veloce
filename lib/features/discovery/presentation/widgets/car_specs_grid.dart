import 'package:flutter/material.dart';

import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

import '../../domain/entities/vehicle_detail.dart';
import 'info_card.dart';

/// Two-column grid of the car's key facts in a white card.
class CarSpecsGrid extends StatelessWidget {
  const CarSpecsGrid({required this.detail, super.key});

  final VehicleDetail detail;

  @override
  Widget build(BuildContext context) {
    final vehicle = detail.vehicle;
    final specs = [
      ('Transmission', vehicle.transmission.label),
      ('Seats', '${vehicle.seats}'),
      ('Fuel', vehicle.fuel.label),
      ('Type', vehicle.type.label),
      ('Year', '${vehicle.year}'),
      ('Plate', vehicle.plate),
    ];
    return InfoCard(
      child: Wrap(
        runSpacing: AppSpacing.md + 2,
        children: [
          for (final (label, value) in specs)
            FractionallySizedBox(
              widthFactor: 0.5,
              child: _Spec(label: label, value: value),
            ),
        ],
      ),
    );
  }
}

class _Spec extends StatelessWidget {
  const _Spec({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label.copyWith(color: colors.muted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.body.copyWith(
            color: colors.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
