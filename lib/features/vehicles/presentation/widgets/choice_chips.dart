import 'package:flutter/material.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

/// A labelled single-choice group of pills, as the wizard shows for vehicle
/// type, neighbourhood, transmission, fuel and seats.
class ChoiceChipGroup<T> extends StatelessWidget {
  const ChoiceChipGroup({
    required this.label,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    super.key,
    this.errorText,
  });

  final String label;
  final List<T> options;
  final T? selected;
  final String Function(T option) labelOf;
  final ValueChanged<T> onSelected;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: colors.muted)),
        const SizedBox(height: AppSpacing.sm - 2),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final option in options)
              ChoiceChip(
                label: Text(labelOf(option)),
                selected: option == selected,
                showCheckmark: false,
                onSelected: (_) => onSelected(option),
                backgroundColor: colors.surface,
                selectedColor: colors.brand,
                side: BorderSide(
                  color: option == selected ? colors.brand : colors.line,
                  width: 1.5,
                ),
                shape: const StadiumBorder(),
                labelStyle: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: option == selected ? colors.onBrand : colors.ink,
                ),
              ),
          ],
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm - 2),
            child: Text(
              errorText!,
              style: AppTextStyles.caption.copyWith(color: colors.danger),
            ),
          ),
      ],
    );
  }
}
