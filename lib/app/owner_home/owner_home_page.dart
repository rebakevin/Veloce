import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/brand_mark.dart';
import 'package:veloce/features/booking/booking.dart';
import 'package:veloce/features/finances/finances.dart';
import 'package:veloce/features/vehicles/vehicles.dart';

/// Owner dashboard. Each card is a slot owned by one feature, so no two
/// features edit this file.
class OwnerHomePage extends StatelessWidget {
  const OwnerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl - AppSpacing.xs,
            AppSpacing.lg,
            AppSpacing.xl - AppSpacing.xs,
            AppSpacing.xl,
          ),
          children: const [
            Center(child: BrandMark()),
            SizedBox(height: AppSpacing.lg),
            _OwnerHeadline(),
            SizedBox(height: AppSpacing.lg),
            _ListCarCard(),
            SizedBox(height: AppSpacing.md),
            PendingRequestsCard(),
            SizedBox(height: AppSpacing.md),
            CarCountCard(),
            SizedBox(height: AppSpacing.md),
            UpcomingRentalsCard(),
            SizedBox(height: AppSpacing.md),
            FinancesCard(),
          ],
        ),
      ),
    );
  }
}

class _OwnerHeadline extends StatelessWidget {
  const _OwnerHeadline();

  static String _greeting(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _greeting(DateTime.now().hour),
          style: AppTextStyles.body.copyWith(
            color: colors.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Put your car to work.',
          style: AppTextStyles.display.copyWith(color: colors.ink),
        ),
      ],
    );
  }
}

/// The brand-colored "List a car" call to action at the top of the dashboard.
class _ListCarCard extends StatelessWidget {
  const _ListCarCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.brand,
      borderRadius: BorderRadius.circular(AppRadius.sheet),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(RouteNames.ownerCarNew),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl - AppSpacing.xs),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'List a car',
                      style: AppTextStyles.title.copyWith(
                        color: colors.onBrand,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Seven short steps. You review before it goes live.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colors.onBrand,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.ink,
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(
                  dimension: AppSizes.iconControl,
                  child: Icon(Icons.add, color: colors.ground),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
