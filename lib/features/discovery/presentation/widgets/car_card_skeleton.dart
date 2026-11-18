import 'package:flutter/material.dart';

import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';

/// Simple skeleton used while result and saved lists load.
class CarCardSkeleton extends StatelessWidget {
  const CarCardSkeleton({super.key, this.width});

  final double? width;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget box(double height, {double? width}) => Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: colors.sand,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
    );
    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(aspectRatio: 16 / 10, child: box(0)),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  box(18, width: 180),
                  const SizedBox(height: AppSpacing.sm),
                  box(13, width: 220),
                  const SizedBox(height: AppSpacing.sm),
                  box(13, width: 130),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
