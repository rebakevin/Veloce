import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/firestore_fields.dart';
import '../../domain/entities/renter_lock.dart';
import 'wire.dart';

/// Maps [RenterLock] to and from the Firestore wire map.
abstract final class RenterLockModel {
  static RenterLock fromMap(String docId, Map<String, dynamic> map) {
    final wire = WireReader('RenterLock', map);
    return RenterLock(
      renterId: docId,
      bookingId: wire.string(FirestoreFields.bookingId),
      createdAt: wire.dateTime(FirestoreFields.createdAt),
    );
  }

  static Map<String, dynamic> toMap(RenterLock entity) => {
    FirestoreFields.bookingId: entity.bookingId,
    FirestoreFields.createdAt: Timestamp.fromDate(entity.createdAt),
  };
}
