import 'package:flutter/material.dart';
import 'package:veloce/core/formatting/formatters.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

/// Shows the two key figures: Total earned and Total losses.
class FinanceTiles extends StatelessWidget {
  const FinanceTiles({
    required this.totalEarned,
    required this.totalLosses,
    super.key,
  });

  final int totalEarned;
  final int totalLosses;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        Expanded(
          child: _Tile(
            label: 'Total earned',
            amount: Formatters.rwf(totalEarned),
            amountColor: colors.ink,
            backgroundColor: colors.surface,
            borderColor: colors.line,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _Tile(
            label: 'Total losses',
            amount: Formatters.rwf(totalLosses),
            amountColor: totalLosses > 0 ? colors.danger : colors.ink,
            backgroundColor: colors.surface,
            borderColor: colors.line,
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.amount,
    required this.amountColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  final String label;
  final String amount;
  final Color amountColor;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: colors.muted),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            amount,
            style: AppTextStyles.cardTitle.copyWith(
              color: amountColor,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
