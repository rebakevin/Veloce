import 'package:flutter/material.dart';

import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/formatting/formatters.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/status_chip.dart';

import '../../domain/entities/booking_view.dart';
import 'booking_thumb.dart';

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
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BookingThumb(),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${vehicle.make} ${vehicle.model}',
                      style: AppTextStyles.cardTitle.copyWith(
                        color: colors.ink,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${Formatters.dateRange(booking.startDate, booking.endDate)}'
                      ' · ${counterpart.name}',
                      style: AppTextStyles.caption.copyWith(
                        color: colors.muted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: StatusChip.booking(view.effectiveStatus),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${Formatters.rwf(booking.totalPayable)}'
                            ' · ${booking.reference}',
                            style: AppTextStyles.caption.copyWith(
                              color: colors.ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: colors.brand,
                        ),
                      ],
                    ),
                    if (actions.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: actions,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
