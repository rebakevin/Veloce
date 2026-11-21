import 'package:flutter/material.dart';

import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

/// The Veloce logo mark and name.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: 'Veloce',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.brand,
              borderRadius: BorderRadius.circular(AppRadius.sm - 2),
            ),
            child: SizedBox.square(
              dimension: 32,
              child: Icon(
                Icons.directions_car_outlined,
                color: colors.onBrand,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'veloce',
            style: AppTextStyles.title.copyWith(
              color: colors.ink,
              fontSize: 23,
              letterSpacing: -0.7,
            ),
          ),
        ],
      ),
    );
  }
}
