import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Two-or-more option switch in a white pill, the selected option filled with
/// the brand color (the Explore / Saved switch of the renter home).
class PillSegmented extends StatelessWidget {
  const PillSegmented({
    required this.labels,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Row(
          children: [
            for (var index = 0; index < labels.length; index++) ...[
              if (index > 0) const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Semantics(
                  button: true,
                  selected: index == selected,
                  child: Material(
                    color: index == selected
                        ? colors.brand
                        : Colors.transparent,
                    shape: const StadiumBorder(),
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: () => onSelected(index),
                      child: SizedBox(
                        height: AppSizes.iconControl,
                        child: Center(
                          child: Text(
                            labels[index],
                            style: AppTextStyles.button.copyWith(
                              color: index == selected
                                  ? colors.onBrand
                                  : colors.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
