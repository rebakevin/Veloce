import 'package:flutter/material.dart';

import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

/// Six-step booking timeline. It scrolls horizontally so it never overflows on
/// a small phone or in landscape.
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
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _steps.length,
        separatorBuilder: (context, index) => SizedBox(
          width: 22,
          child: Center(
            child: Container(
              height: 2,
              color: index < completed - 1 ? colors.brand : colors.line,
            ),
          ),
        ),
        itemBuilder: (context, index) {
          final isDone = index < completed;
          final isCurrent =
              !_hasEnded && index == completed && completed < _steps.length;
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
          return SizedBox(
            width: 62,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
                          '${index + 1}',
                          style: AppTextStyles.label.copyWith(
                            color: foreground,
                          ),
                        ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _steps[index],
                  textAlign: TextAlign.center,
                  style:
                      (isDone || isCurrent
                              ? AppTextStyles.caption
                              : AppTextStyles.label)
                          .copyWith(
                            color: isDone || isCurrent
                                ? colors.ink
                                : colors.muted,
                          ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
