import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/firestore_fields.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/enums/notification_type.dart';
import 'wire.dart';

/// Maps [AppNotification] to and from the Firestore wire map.
abstract final class AppNotificationModel {
  static AppNotification fromMap(String docId, Map<String, dynamic> map) {
    final wire = WireReader('AppNotification', map);
    return AppNotification(
      id: docId,
      userId: wire.string(FirestoreFields.userId),
      type: wire.enumValue(FirestoreFields.type, NotificationType.fromKey),
      title: wire.string(FirestoreFields.title),
      text: wire.string(FirestoreFields.text),
      bookingId: wire.optionalString(FirestoreFields.bookingId),
      read: wire.boolean(FirestoreFields.read),
      createdAt: wire.dateTime(FirestoreFields.createdAt),
    );
  }

  static Map<String, dynamic> toMap(AppNotification entity) => {
    FirestoreFields.userId: entity.userId,
    FirestoreFields.type: entity.type.key,
    FirestoreFields.title: entity.title,
    FirestoreFields.text: entity.text,
    FirestoreFields.bookingId: entity.bookingId,
    FirestoreFields.read: entity.read,
    FirestoreFields.createdAt: Timestamp.fromDate(entity.createdAt),
  };
}
