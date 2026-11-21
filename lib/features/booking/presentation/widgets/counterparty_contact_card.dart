import 'package:flutter/material.dart';

import 'package:veloce/core/domain/entities/booking_contact.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

import '../../domain/entities/booking_view.dart';

/// The other side's phone, email and meeting point. Shows the locked tile
/// until the booking is paid.
class CounterpartyContactCard extends StatelessWidget {
  const CounterpartyContactCard({
    required this.view,
    required this.role,
    super.key,
    this.contact,
  });

  final BookingView view;
  final UserRole role;
  final BookingContact? contact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final unlocked = view.isContactUnlocked;
    final value = contact;
    final label = AppTextStyles.bodySmall.copyWith(color: colors.muted);
    final data = AppTextStyles.bodySmall.copyWith(
      color: colors.ink,
      fontWeight: FontWeight.w700,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.brandWash,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (!unlocked) ...[
                  Icon(Icons.lock_outline, size: 16, color: colors.brandDeep),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Text(
                  role == UserRole.renter ? 'Owner contact' : 'Renter contact',
                  style: AppTextStyles.label.copyWith(color: colors.brandDeep),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (!unlocked)
              Text(
                'Contact details unlock after payment.',
                style: AppTextStyles.bodySmall.copyWith(color: colors.ink),
              )
            else if (value == null)
              Text(
                'Contact details are not available yet.',
                style: AppTextStyles.caption.copyWith(color: colors.muted),
              )
            else ...[
              _Row(label: 'Phone', value: value.phone, a: label, b: data),
              _Row(label: 'Email', value: value.email, a: label, b: data),
              if (role == UserRole.renter && value.meetingPoint != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text('Meet at: ${value.meetingPoint}', style: data),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    required this.a,
    required this.b,
  });

  final String label;
  final String value;
  final TextStyle a;
  final TextStyle b;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: a),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(value, textAlign: TextAlign.end, style: b),
          ),
        ],
      ),
    );
  }
}
