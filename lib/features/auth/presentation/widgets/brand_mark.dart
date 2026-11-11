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
          Icon(Icons.directions_car_filled, color: colors.brand, size: 32),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Veloce',
            style: AppTextStyles.title.copyWith(color: colors.ink),
          ),
        ],
      ),
    );
  }
}
