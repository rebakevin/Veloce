import 'package:equatable/equatable.dart';

import '../enums/notification_type.dart';

/// An in-app notification for one user.
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.text,
    required this.bookingId,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String text;
  final String? bookingId;
  final bool read;
  final DateTime createdAt;

  AppNotification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? text,
    String? bookingId,
    bool? read,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      text: text ?? this.text,
      bookingId: bookingId ?? this.bookingId,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    type,
    title,
    text,
    bookingId,
    read,
    createdAt,
  ];
}
