import 'package:flutter/material.dart';
import 'package:veloce/core/domain/enums/document_kind.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

/// Tells the owner the car is paused because a required paper expired.
class PausedByExpiryBanner extends StatelessWidget {
  const PausedByExpiryBanner({required this.expired, super.key});

  final Set<DocumentKind> expired;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final names = expired.map((kind) => kind.label.toLowerCase()).join(' and ');
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.cautionWash,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded, color: colors.cautionInk),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paused by expiry',
                    style: AppTextStyles.cardTitle.copyWith(
                      color: colors.cautionInk,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Your $names has expired, so renters cannot book this '
                    'car. Replace it below, then resume the listing.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: colors.cautionBody,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
