import 'package:flutter/material.dart';

import '../domain/enums/booking_status.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

enum StatusTone { neutral, info, active, caution, danger, review }

/// Status badge. It always carries text so colour is never the only signal.
class StatusChip extends StatelessWidget {
  const StatusChip({required this.label, required this.tone, super.key});

  factory StatusChip.booking(BookingStatus status, {Key? key}) {
    return StatusChip(key: key, label: status.label, tone: _toneFor(status));
  }

  final String label;
  final StatusTone tone;

  static StatusTone _toneFor(BookingStatus status) => switch (status) {
    BookingStatus.pending => StatusTone.caution,
    BookingStatus.approved => StatusTone.info,
    BookingStatus.confirmed || BookingStatus.active => StatusTone.active,
    BookingStatus.returning => StatusTone.review,
    BookingStatus.review => StatusTone.danger,
    BookingStatus.declined => StatusTone.danger,
    BookingStatus.cancelled ||
    BookingStatus.expired ||
    BookingStatus.completed => StatusTone.neutral,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (background, foreground) = switch (tone) {
      StatusTone.neutral => (colors.sand, colors.inkSoft),
      StatusTone.info => (colors.brandWash, colors.brandDeep),
      StatusTone.active => (colors.brandTint, colors.brandDeep),
      StatusTone.caution => (colors.cautionWash, colors.cautionInk),
      StatusTone.danger => (colors.dangerWash, colors.danger),
      StatusTone.review => (colors.reviewWash, colors.reviewInk),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 6,
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(color: foreground),
        ),
      ),
    );
  }
}
