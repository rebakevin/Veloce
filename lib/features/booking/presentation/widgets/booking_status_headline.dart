import 'package:flutter/material.dart';

import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/status_chip.dart';

import '../../domain/entities/booking_view.dart';

/// Status chip plus the plain-language sentence for the current side.
class BookingStatusHeadline extends StatelessWidget {
  const BookingStatusHeadline({
    required this.view,
    required this.role,
    super.key,
  });

  final BookingView view;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final status = view.effectiveStatus;
    final reason = view.booking.reason;
    final text = switch (status) {
      BookingStatus.pending =>
        role == UserRole.owner
            ? 'Review the renter and decide whether to approve this request.'
            : 'Waiting for the owner to review your request.',
      BookingStatus.approved =>
        role == UserRole.owner
            ? 'Waiting for the renter to pay before the deadline.'
            : 'Approved. Pay before the deadline to confirm your booking.',
      BookingStatus.confirmed =>
        role == UserRole.owner
            ? 'Paid and confirmed. The renter will collect the car.'
            : 'Paid and confirmed. Contact details are unlocked.',
      BookingStatus.active => 'The rental is active.',
      BookingStatus.returning => 'Return inspection in progress.',
      BookingStatus.review => 'The caution claim is open.',
      BookingStatus.completed => 'This rental is complete.',
      BookingStatus.declined => reason ?? 'This request was declined.',
      BookingStatus.cancelled => reason ?? 'This booking was cancelled.',
      BookingStatus.expired => reason ?? 'This booking expired.',
    };
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            StatusChip.booking(status),
            Text(
              view.booking.reference,
              style: AppTextStyles.label.copyWith(
                color: colors.muted,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          _headline(status, role),
          style: AppTextStyles.title.copyWith(color: colors.ink, fontSize: 24),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(text, style: AppTextStyles.body.copyWith(color: colors.body)),
      ],
    );
  }

  static String _headline(BookingStatus status, UserRole role) =>
      switch (status) {
        BookingStatus.pending =>
          role == UserRole.owner ? 'New request' : 'Waiting for the owner',
        BookingStatus.approved =>
          role == UserRole.owner ? 'Waiting for payment' : 'Ready to pay',
        BookingStatus.confirmed => 'Booking confirmed',
        BookingStatus.active => 'Rental in progress',
        BookingStatus.returning => 'Return in progress',
        BookingStatus.review => 'Caution claim open',
        BookingStatus.completed => 'Rental complete',
        BookingStatus.declined => 'Request declined',
        BookingStatus.cancelled => 'Booking cancelled',
        BookingStatus.expired => 'Booking expired',
      };
}
