import 'package:flutter/material.dart';

import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

/// A muted label on the left and a bold value on the right.
class LabelValueRow extends StatelessWidget {
  const LabelValueRow({
    required this.label,
    required this.value,
    super.key,
    this.trailing,
  });

  final String label;
  final String value;

  /// Replaces the text [value] (a status chip, for example).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.md - 2,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: colors.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
        Flexible(
          child:
              trailing ??
              Text(
                value,
                textAlign: TextAlign.end,
                style: AppTextStyles.bodySmall.copyWith(
                  color: colors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
        ),
      ],
    );
  }
}
