import 'package:flutter/material.dart';

import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

/// Map block and pickup note. The map is a placeholder: the exact meeting
/// point is shared by the owner after the booking is confirmed.
class PickupCard extends StatelessWidget {
  const PickupCard({required this.neighbourhood, super.key});

  final String neighbourhood;

  static const double _mapHeight = 110;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: _mapHeight,
              child: ColoredBox(
                color: colors.sand,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: AppSpacing.sm,
                    children: [
                      Icon(Icons.place_outlined, color: colors.brand),
                      Text(
                        neighbourhood,
                        style: AppTextStyles.caption.copyWith(
                          color: colors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md + 2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pickup and return',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: colors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '$neighbourhood, Kigali. The exact meeting point is '
                    'shared by the owner after the booking is confirmed. No '
                    'delivery.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: colors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
