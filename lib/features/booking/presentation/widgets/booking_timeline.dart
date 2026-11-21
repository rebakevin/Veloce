import 'package:flutter/material.dart';

import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

/// Six-step booking timeline sharing the card width evenly.
class BookingTimeline extends StatelessWidget {
  const BookingTimeline({required this.status, super.key});

  final BookingStatus status;

  static const List<String> _steps = [
    'Request',
    'Approved',
    'Paid',
    'Handover',
    'Return',
    'Done',
  ];

  int get _completedSteps => switch (status) {
    BookingStatus.pending => 1,
    BookingStatus.approved => 2,
    BookingStatus.confirmed => 3,
    BookingStatus.active => 4,
    BookingStatus.returning => 4,
    BookingStatus.review => 5,
    BookingStatus.completed => 6,
    BookingStatus.declined ||
    BookingStatus.cancelled ||
    BookingStatus.expired => 1,
  };

  /// A declined, cancelled or expired booking stopped; no step is "next".
  bool get _hasEnded =>
      status == BookingStatus.declined ||
      status == BookingStatus.cancelled ||
      status == BookingStatus.expired;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final completed = _completedSteps;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < _steps.length; index++)
          Expanded(
            child: _Step(
              label: _steps[index],
              number: index + 1,
              isDone: index < completed,
              isCurrent:
                  !_hasEnded && index == completed && completed < _steps.length,
              colors: colors,
            ),
          ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.label,
    required this.number,
    required this.isDone,
    required this.isCurrent,
    required this.colors,
  });

  final String label;
  final int number;
  final bool isDone;
  final bool isCurrent;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final background = isDone
        ? colors.brand
        : isCurrent
        ? colors.brandWash
        : colors.sand;
    final foreground = isDone
        ? colors.onBrand
        : isCurrent
        ? colors.brandDeep
        : colors.muted;
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            border: isCurrent
                ? Border.all(color: colors.brand, width: 2)
                : null,
          ),
          child: isDone
              ? Icon(Icons.check, size: 16, color: foreground)
              : Text(
                  '$number',
                  style: AppTextStyles.label.copyWith(color: foreground),
                ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTextStyles.label.copyWith(
            fontSize: 10.5,
            color: isDone || isCurrent ? colors.ink : colors.muted,
          ),
        ),
      ],
    );
  }
}
