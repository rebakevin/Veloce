import 'package:flutter/material.dart';

import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

/// Big screen heading with an optional muted line under it.
class StepHeader extends StatelessWidget {
  const StepHeader({required this.title, super.key, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final sub = subtitle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.display.copyWith(color: context.colors.ink),
        ),
        if (sub != null) ...[
          const SizedBox(height: AppSpacing.xs + 2),
          Text(
            sub,
            style: AppTextStyles.bodyLarge.copyWith(
              color: context.colors.muted,
            ),
          ),
        ],
      ],
    );
  }
}
