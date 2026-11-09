import '../enums/notification_type.dart';
import 'atomic_write.dart';

/// Queues an in-app notification for a user inside an [AtomicWrite].
abstract interface class NotificationWriter {
  void send(
    AtomicWrite write, {
    required String userId,
    required NotificationType type,
    required String title,
    required String text,
    String? bookingId,
  });
}
