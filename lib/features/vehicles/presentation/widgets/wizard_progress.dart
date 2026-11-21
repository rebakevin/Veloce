import 'package:flutter/material.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

/// Segmented progress bar with the "Step N of M · title" caption.
class WizardProgress extends StatelessWidget {
  const WizardProgress({
    required this.step,
    required this.total,
    required this.title,
    super.key,
  });

  final int step;
  final int total;
  final String title;

  static const double _segmentHeight = 6;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var index = 1; index <= total; index++) ...[
              if (index > 1) const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: index <= step ? colors.brand : colors.sand,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: const SizedBox(height: _segmentHeight),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Step $step of $total · $title',
          style: AppTextStyles.caption.copyWith(color: colors.muted),
        ),
      ],
    );
  }
}

/// White rounded card holding one wizard step, with its heading.
class WizardStepCard extends StatelessWidget {
  const WizardStepCard({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.title.copyWith(color: context.colors.ink),
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}
