import 'package:flutter/material.dart';
import 'package:veloce/core/domain/entities/app_notification.dart';
import 'package:veloce/core/domain/enums/notification_type.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

class NotificationVisuals {
  const NotificationVisuals({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;

  static NotificationVisuals forType(NotificationType type, AppColors colors) {
    return switch (type) {
      NotificationType.requestReceived => NotificationVisuals(
        icon: Icons.mail_outline,
        backgroundColor: colors.brandWash,
        iconColor: colors.brand,
      ),
      NotificationType.requestApproved => NotificationVisuals(
        icon: Icons.check_circle_outline,
        backgroundColor: colors.brandWash,
        iconColor: colors.brand,
      ),
      NotificationType.requestDeclined => NotificationVisuals(
        icon: Icons.cancel_outlined,
        backgroundColor: colors.dangerWash,
        iconColor: colors.danger,
      ),
      NotificationType.requestExpired => NotificationVisuals(
        icon: Icons.hourglass_disabled_outlined,
        backgroundColor: colors.sand,
        iconColor: colors.muted,
      ),
      NotificationType.bookingCancelled => NotificationVisuals(
        icon: Icons.event_busy_outlined,
        backgroundColor: colors.dangerWash,
        iconColor: colors.danger,
      ),
      NotificationType.paymentReceived => NotificationVisuals(
        icon: Icons.payments_outlined,
        backgroundColor: colors.brandWash,
        iconColor: colors.brand,
      ),
      NotificationType.paymentDeadline => NotificationVisuals(
        icon: Icons.alarm_outlined,
        backgroundColor: colors.cautionWash,
        iconColor: colors.cautionInk,
      ),
      NotificationType.pickupConfirmed => NotificationVisuals(
        icon: Icons.key_outlined,
        backgroundColor: colors.brandWash,
        iconColor: colors.brand,
      ),
      NotificationType.returnConfirmed => NotificationVisuals(
        icon: Icons.done_all_outlined,
        backgroundColor: colors.brandWash,
        iconColor: colors.brand,
      ),
      NotificationType.claimChanged => NotificationVisuals(
        icon: Icons.gavel_outlined,
        backgroundColor: colors.cautionWash,
        iconColor: colors.cautionInk,
      ),
      NotificationType.lateFeeApplied => NotificationVisuals(
        icon: Icons.warning_amber_outlined,
        backgroundColor: colors.dangerWash,
        iconColor: colors.danger,
      ),
      NotificationType.reviewDue => NotificationVisuals(
        icon: Icons.rate_review_outlined,
        backgroundColor: colors.reviewWash,
        iconColor: colors.reviewInk,
      ),
    };
  }
}

String _formatTimeAgo(DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);
  if (diff.isNegative || diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${dateTime.day} ${months[dateTime.month - 1]}';
}

/// Renders a single notification with an icon per type, unread dot,
/// relative timestamp, and swipe-to-dismiss support.
class NotificationTile extends StatelessWidget {
  const NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
    super.key,
  });

  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final visuals = NotificationVisuals.forType(notification.type, colors);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.dangerWash,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Icon(Icons.delete_outline, color: colors.danger),
      ),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: visuals.backgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(visuals.icon, color: visuals.iconColor, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: AppTextStyles.body.copyWith(
                                color: colors.ink,
                                fontWeight: notification.read
                                    ? FontWeight.w600
                                    : FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            _formatTimeAgo(notification.createdAt),
                            style: AppTextStyles.caption.copyWith(
                              color: colors.muted,
                            ),
                          ),
                          if (!notification.read) ...[
                            const SizedBox(width: AppSpacing.xs),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: colors.star,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.text,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: colors.body,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
