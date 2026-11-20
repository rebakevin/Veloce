import 'package:veloce/core/domain/entities/app_notification.dart';
import 'package:veloce/core/error/result.dart';

/// Contract for notifications persistence and streams.
abstract interface class NotificationsRepository {
  /// Live stream of notifications for [userId], ordered newest first.
  Stream<List<AppNotification>> watchNotifications(String userId);

  /// Fetch a one-off list of notifications for [userId], ordered newest first.
  Future<Result<List<AppNotification>>> getNotifications(String userId);

  /// Marks a single notification as read.
  Future<Result<void>> markAsRead(String notificationId);

  /// Marks all unread notifications for [userId] as read.
  Future<Result<void>> markAllAsRead(String userId);

  /// Deletes a single notification.
  Future<Result<void>> deleteNotification(String notificationId);

  /// Deletes all notifications for [userId].
  Future<Result<void>> clearAllNotifications(String userId);
}
