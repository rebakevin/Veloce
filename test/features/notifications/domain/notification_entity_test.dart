import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/data/models/app_notification_model.dart';
import 'package:veloce/core/domain/entities/app_notification.dart';
import 'package:veloce/core/domain/enums/notification_type.dart';

void main() {
  final testDate = DateTime(2026, 11, 15, 12, 0);

  group('AppNotification', () {
    test('copyWith updates fields correctly', () {
      final notif = AppNotification(
        id: 'notif-1',
        userId: 'user-1',
        type: NotificationType.requestReceived,
        title: 'New request',
        text: 'Rental request received',
        bookingId: 'booking-1',
        read: false,
        createdAt: testDate,
      );

      final updated = notif.copyWith(read: true, title: 'Updated request');
      expect(updated.read, isTrue);
      expect(updated.title, 'Updated request');
      expect(updated.id, 'notif-1');
      expect(updated.type, NotificationType.requestReceived);
    });

    test('equality and props work as expected', () {
      final a = AppNotification(
        id: 'notif-1',
        userId: 'user-1',
        type: NotificationType.reviewDue,
        title: 'Review due',
        text: 'Leave a review',
        bookingId: null,
        read: false,
        createdAt: testDate,
      );

      final b = AppNotification(
        id: 'notif-1',
        userId: 'user-1',
        type: NotificationType.reviewDue,
        title: 'Review due',
        text: 'Leave a review',
        bookingId: null,
        read: false,
        createdAt: testDate,
      );

      expect(a, equals(b));
    });
  });

  group('AppNotificationModel', () {
    test('serializes to map and deserializes from map correctly', () {
      final original = AppNotification(
        id: 'p6-owner1-01',
        userId: 'owner1',
        type: NotificationType.requestReceived,
        title: 'New booking request',
        text: 'A renter wants to rent your car.',
        bookingId: 'booking-p6-o1-m4',
        read: false,
        createdAt: testDate,
      );

      final map = AppNotificationModel.toMap(original);
      expect(map['userId'], 'owner1');
      expect(map['type'], 'request_received');
      expect(map['bookingId'], 'booking-p6-o1-m4');
      expect(map['read'], isFalse);
      expect(map['createdAt'], isA<Timestamp>());

      final deserialized = AppNotificationModel.fromMap('p6-owner1-01', map);
      expect(deserialized.id, original.id);
      expect(deserialized.userId, original.userId);
      expect(deserialized.type, original.type);
      expect(deserialized.title, original.title);
      expect(deserialized.text, original.text);
      expect(deserialized.bookingId, original.bookingId);
      expect(deserialized.read, original.read);
      expect(deserialized.createdAt, original.createdAt);
    });
  });
}
