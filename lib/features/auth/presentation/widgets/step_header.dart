import 'package:flutter/material.dart';

import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

/// "Step 2 of 4" with a progress bar and the step title.
class StepHeader extends StatelessWidget {
  const StepHeader({
    required this.step,
    required this.total,
    required this.title,
    super.key,
    this.subtitle,
  });

  final int step;
  final int total;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final sub = subtitle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: 'Step $step of $total',
          child: LinearProgressIndicator(
            value: step / total,
            minHeight: 6,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(title, style: AppTextStyles.title),
        if (sub != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(sub, style: AppTextStyles.body),
        ],
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}
