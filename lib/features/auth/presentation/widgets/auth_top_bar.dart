import 'package:flutter/material.dart';

import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

/// Top row of the sign-up screens: a white round back button and, when given,
/// the "Step 1 of 3" label on the right.
class AuthTopBar extends StatelessWidget {
  const AuthTopBar({required this.onBack, super.key, this.step, this.total});

  final VoidCallback onBack;
  final int? step;
  final int? total;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final current = step;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Material(
          color: colors.surface,
          shape: const CircleBorder(),
          child: IconButton(
            tooltip: 'Back',
            color: colors.ink,
            iconSize: 22,
            constraints: const BoxConstraints.tightFor(
              width: AppSizes.iconControl,
              height: AppSizes.iconControl,
            ),
            icon: const Icon(Icons.arrow_back),
            onPressed: onBack,
          ),
        ),
        if (current != null)
          Text(
            'Step $current of $total',
            style: AppTextStyles.caption.copyWith(
              color: colors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}
