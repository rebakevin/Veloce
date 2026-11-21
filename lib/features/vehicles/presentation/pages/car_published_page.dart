import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/primary_button.dart';

class CarPublishedPage extends StatelessWidget {
  const CarPublishedPage({required this.vehicleId, super.key});

  final String vehicleId;

  static const double _badgeSize = 72;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl - AppSpacing.xs,
            AppSpacing.xl + AppSpacing.sm,
            AppSpacing.xl - AppSpacing.xs,
            AppSpacing.xl,
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.brandTint,
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(
                  dimension: _badgeSize,
                  child: Icon(Icons.check, size: 36, color: colors.brandDeep),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg + 2),
            Text(
              'Your car is live',
              style: AppTextStyles.display.copyWith(
                color: colors.ink,
                fontSize: 32,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Renters can only find it once you set the dates it is '
              'available. You can also pause it or change the price any '
              'time from My cars.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Set availability',
              onPressed: () =>
                  context.push(RouteNames.ownerCarAvailability(vehicleId)),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: () => context.push(RouteNames.car(vehicleId)),
              child: const Text('View listing'),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: () => context.go(RouteNames.ownerCars),
              child: const Text('Manage my cars'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => context.go(RouteNames.ownerHome),
              child: const Text('Back to home'),
            ),
          ],
        ),
      ),
    );
  }
}
