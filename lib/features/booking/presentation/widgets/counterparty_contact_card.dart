import 'package:flutter/material.dart';

import 'package:veloce/core/domain/entities/booking_contact.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/locked_contact_tile.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          role == UserRole.renter ? 'Owner contact' : 'Renter contact',
          style: AppTextStyles.cardTitle,
        ),
        const SizedBox(height: AppSpacing.sm),
        LockedContactTile(
          isLocked: !unlocked,
          phone: value?.phone,
          email: value?.email,
          meetingPoint: role == UserRole.renter ? value?.meetingPoint : null,
        ),
        if (unlocked && value == null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Contact details are not available yet.',
            style: AppTextStyles.caption.copyWith(color: colors.muted),
          ),
        ],
      ],
    );
  }
}
