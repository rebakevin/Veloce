import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Contact details of the other party. Locked until payment, then revealed.
class LockedContactTile extends StatelessWidget {
  const LockedContactTile({
    required this.isLocked,
    super.key,
    this.phone,
    this.email,
    this.meetingPoint,
  });

  final bool isLocked;
  final String? phone;
  final String? email;
  final String? meetingPoint;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isLocked ? Icons.lock_outline : Icons.lock_open_outlined,
              color: colors.brand,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: isLocked
                  ? const Text('Contact details unlock after payment.')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (phone != null)
                          Text(phone!, style: AppTextStyles.cardTitle),
                        if (email != null) Text(email!),
                        if (meetingPoint != null)
                          Text('Meet at: $meetingPoint'),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
