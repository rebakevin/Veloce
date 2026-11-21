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
            dotColor: colors.brand,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _Tile(
            label: 'Total losses',
            amount: Formatters.rwf(totalLosses),
            amountColor: colors.ink,
            dotColor: colors.star,
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
    required this.dotColor,
  });

  final String label;
  final String amount;
  final Color amountColor;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: dotColor,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const SizedBox(width: 10, height: 10),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.label.copyWith(color: colors.muted),
                ),
              ),
            ],
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
