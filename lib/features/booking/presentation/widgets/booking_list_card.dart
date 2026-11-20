import 'package:flutter/material.dart';

import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/formatting/formatters.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/status_chip.dart';

import '../../domain/entities/booking_view.dart';

/// One booking row for both My Activity screens.
class BookingListCard extends StatelessWidget {
  const BookingListCard({
    required this.view,
    required this.role,
    required this.onTap,
    super.key,
    this.actions = const [],
  });

  final BookingView view;
  final UserRole role;
  final VoidCallback onTap;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final booking = view.booking;
    final vehicle = view.vehicle;
    final counterpart = view.counterpartFor(role);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${vehicle.make} ${vehicle.model}',
                          style: AppTextStyles.cardTitle,
                        ),
                        Text(
                          vehicle.plate,
                          style: AppTextStyles.label.copyWith(
                            color: colors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusChip.booking(view.effectiveStatus),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                Formatters.dateRange(booking.startDate, booking.endDate),
                style: AppTextStyles.body,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${booking.reference} · ${counterpart.name}',
                style: AppTextStyles.caption.copyWith(color: colors.muted),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                Formatters.rwf(booking.totalPayable),
                style: AppTextStyles.bodyLarge,
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: actions,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
