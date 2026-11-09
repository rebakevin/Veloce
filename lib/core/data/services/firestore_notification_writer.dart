import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/firestore_fields.dart';
import '../../constants/firestore_paths.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/enums/notification_type.dart';
import '../../domain/services/atomic_write.dart';
import '../../domain/services/clock.dart';
import '../../domain/services/notification_writer.dart';
import '../models/app_notification_model.dart';

class FirestoreNotificationWriter implements NotificationWriter {
  const FirestoreNotificationWriter(this._clock);

  final Clock _clock;

  @override
  void send(
    AtomicWrite write, {
    required String userId,
    required NotificationType type,
    required String title,
    required String text,
    String? bookingId,
  }) {
    final id = write.newId(FirestorePaths.notifications);
    final notification = AppNotification(
      id: id,
      userId: userId,
      type: type,
      title: title,
      text: text,
      bookingId: bookingId,
      read: false,
      createdAt: _clock.now(),
    );
    write.set(
      '${FirestorePaths.notifications}/$id',
      AppNotificationModel.toMap(notification)
        ..[FirestoreFields.createdAt] = FieldValue.serverTimestamp(),
    );
  }
}
