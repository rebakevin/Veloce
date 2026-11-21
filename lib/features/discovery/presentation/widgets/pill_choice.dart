import 'package:flutter/material.dart';

import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

/// A selectable pill: brand-filled when [selected], white with a thin border
/// otherwise (the filter choices).
class PillChoice extends StatelessWidget {
  const PillChoice({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? colors.brand : colors.surface,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? colors.brand : colors.line,
            width: 1.5,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.iconControl),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: selected ? colors.onBrand : colors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
