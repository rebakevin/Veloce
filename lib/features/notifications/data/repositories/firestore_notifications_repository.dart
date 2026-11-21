import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veloce/core/constants/firestore_fields.dart';
import 'package:veloce/core/constants/firestore_paths.dart';
import 'package:veloce/core/data/models/app_notification_model.dart';
import 'package:veloce/core/data/services/failure_mapper.dart';
import 'package:veloce/core/domain/entities/app_notification.dart';
import 'package:veloce/core/domain/services/atomic_write.dart';
import 'package:veloce/core/error/result.dart';

import '../../domain/repositories/notifications_repository.dart';

/// Firestore implementation of [NotificationsRepository].
class FirestoreNotificationsRepository implements NotificationsRepository {
  const FirestoreNotificationsRepository({
    required this._firestore,
    required this._writes,
  });

  final FirebaseFirestore _firestore;
  final AtomicWriteFactory _writes;

  /// Firestore allows 500 writes per batch; stay well under it.
  static const int _batchSize = 400;

  static Iterable<List<T>> _chunks<T>(List<T> items) sync* {
    for (var i = 0; i < items.length; i += _batchSize) {
      final end = i + _batchSize;
      yield items.sublist(i, end > items.length ? items.length : end);
    }
  }

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) {
    return _firestore
        .collection(FirestorePaths.notifications)
        .where(FirestoreFields.userId, isEqualTo: userId)
        .orderBy(FirestoreFields.createdAt, descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppNotificationModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Future<Result<List<AppNotification>>> getNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.notifications)
          .where(FirestoreFields.userId, isEqualTo: userId)
          .orderBy(FirestoreFields.createdAt, descending: true)
          .get();
      final items = snapshot.docs
          .map((doc) => AppNotificationModel.fromMap(doc.id, doc.data()))
          .toList();
      return Result.success(items);
    } catch (e, st) {
      return Result.failure(mapToFailure(e, st));
    }
  }

  @override
  Future<Result<void>> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(FirestorePaths.notifications)
          .doc(notificationId)
          .update({FirestoreFields.read: true});
      return const Result.success(null);
    } catch (e, st) {
      return Result.failure(mapToFailure(e, st));
    }
  }

  @override
  Future<Result<void>> markAllAsRead(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.notifications)
          .where(FirestoreFields.userId, isEqualTo: userId)
          .where(FirestoreFields.read, isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) {
        return const Result.success(null);
      }

      await Future.wait([
        for (final chunk in _chunks(snapshot.docs))
          () {
            final batch = _writes.begin();
            for (final doc in chunk) {
              batch.update('${FirestorePaths.notifications}/${doc.id}', {
                FirestoreFields.read: true,
              });
            }
            return batch.commit();
          }(),
      ]);
      return const Result.success(null);
    } catch (e, st) {
      return Result.failure(mapToFailure(e, st));
    }
  }

  @override
  Future<Result<void>> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection(FirestorePaths.notifications)
          .doc(notificationId)
          .delete();
      return const Result.success(null);
    } catch (e, st) {
      return Result.failure(mapToFailure(e, st));
    }
  }

  @override
  Future<Result<void>> clearAllNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.notifications)
          .where(FirestoreFields.userId, isEqualTo: userId)
          .get();

      if (snapshot.docs.isEmpty) {
        return const Result.success(null);
      }

      await Future.wait([
        for (final chunk in _chunks(snapshot.docs))
          () {
            final batch = _writes.begin();
            for (final doc in chunk) {
              batch.delete('${FirestorePaths.notifications}/${doc.id}');
            }
            return batch.commit();
          }(),
      ]);
      return const Result.success(null);
    } catch (e, st) {
      return Result.failure(mapToFailure(e, st));
    }
  }
}
