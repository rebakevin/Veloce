import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

import '../../domain/entities/vehicle_detail.dart';
import 'info_card.dart';

/// The owner's rental rules as bullets, with the instructions PDF when there
/// is one.
class CarRulesCard extends StatelessWidget {
  const CarRulesCard({required this.detail, super.key});

  final VehicleDetail detail;

  @override
  Widget build(BuildContext context) {
    final vehicle = detail.vehicle;
    final colors = context.colors;
    final rules = [
      if (vehicle.fuelRule.isNotEmpty) 'Fuel: ${vehicle.fuelRule}',
      if (vehicle.smoking.isNotEmpty) 'Smoking: ${vehicle.smoking}',
      ...vehicle.extras,
    ];
    final pdf = vehicle.rulesFileUrl;
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rental rules',
            style: AppTextStyles.bodyLarge.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (rules.isEmpty)
            Text(
              'Ask the owner about any extra rules before pickup.',
              style: AppTextStyles.bodySmall.copyWith(color: colors.muted),
            ),
          for (final rule in rules)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Text(
                '• $rule',
                style: AppTextStyles.bodySmall.copyWith(color: colors.inkSoft),
              ),
            ),
          if (pdf != null) ...[
            const SizedBox(height: AppSpacing.md - 2),
            Divider(color: colors.sand, height: 1),
            const SizedBox(height: AppSpacing.md),
            _PdfRow(url: pdf),
          ],
        ],
      ),
    );
  }
}

class _PdfRow extends StatelessWidget {
  const _PdfRow({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.dangerWash,
            borderRadius: BorderRadius.circular(AppRadius.sm - 4),
          ),
          child: SizedBox(
            width: 42,
            height: 50,
            child: Center(
              child: Text(
                'PDF',
                style: AppTextStyles.label.copyWith(
                  color: colors.danger,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Owner’s instructions',
                style: AppTextStyles.body.copyWith(
                  color: colors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Read before you book',
                style: AppTextStyles.label.copyWith(
                  color: colors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        OutlinedButton(
          onPressed: () => unawaited(
            launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, AppSizes.iconControl),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            textStyle: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          child: const Text('Download'),
        ),
      ],
    );
  }
}
