import 'package:flutter/material.dart';

import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

/// Terms gate shared by the car detail and request review screens: a white
/// card with a checkbox.
class BookingTerms extends StatelessWidget {
  const BookingTerms({
    required this.accepted,
    required this.onChanged,
    super.key,
  });

  final bool accepted;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: () => onChanged(!accepted),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: accepted,
                onChanged: (value) => onChanged(value ?? false),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.md,
                    bottom: AppSpacing.md,
                    right: AppSpacing.sm,
                  ),
                  child: Text(
                    'I agree to the owner’s rules and the Veloce rental terms. '
                    'Self-drive only. The caution fee is refundable.',
                    style: AppTextStyles.bodySmall.copyWith(color: colors.ink),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
