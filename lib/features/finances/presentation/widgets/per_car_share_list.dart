import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:veloce/core/formatting/formatters.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

import '../../domain/entities/car_finance_share.dart';

/// Renders each car's earned, losses, and a share progress bar of total earnings.
class PerCarShareList extends StatelessWidget {
  const PerCarShareList({required this.carShares, super.key});

  final List<CarFinanceShare> carShares;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (carShares.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'By car',
          style: AppTextStyles.cardTitle.copyWith(color: colors.ink),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Column(
            children: [
              for (int i = 0; i < carShares.length; i++) ...[
                if (i > 0) Divider(height: 1, color: colors.line),
                _CarShareRow(share: carShares[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CarShareRow extends StatelessWidget {
  const _CarShareRow({required this.share});

  final CarFinanceShare share;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final vehicle = share.vehicle;
    final percentage = (share.share * 100).toStringAsFixed(0);

    return InkWell(
      onTap: () => context.push(RouteNames.ownerCarFinances(vehicle.id)),
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${vehicle.make} ${vehicle.model}',
                        style: AppTextStyles.cardTitle.copyWith(
                          fontSize: 15,
                          color: colors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        vehicle.plate,
                        style: AppTextStyles.caption.copyWith(
                          color: colors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.rwf(share.earned),
                      style: AppTextStyles.cardTitle.copyWith(
                        fontSize: 15,
                        color: colors.brand,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (share.losses > 0)
                      Text(
                        'Loss: ${Formatters.rwf(share.losses)}',
                        style: AppTextStyles.caption.copyWith(
                          color: colors.danger,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(Icons.chevron_right, color: colors.muted, size: 20),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: LinearProgressIndicator(
                      value: share.share,
                      minHeight: 6,
                      backgroundColor: colors.sand,
                      valueColor: AlwaysStoppedAnimation<Color>(colors.brand),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '$percentage%',
                  style: AppTextStyles.caption.copyWith(
                    color: colors.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
