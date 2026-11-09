import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/firestore_fields.dart';
import '../../domain/entities/calendar_block.dart';
import 'wire.dart';

/// Maps [CalendarBlock] to and from the Firestore wire map.
abstract final class CalendarBlockModel {
  static CalendarBlock fromMap(String docId, Map<String, dynamic> map) {
    final wire = WireReader('CalendarBlock', map);
    return CalendarBlock(
      bookingId: docId,
      vehicleId: wire.string(FirestoreFields.vehicleId),
      startDate: wire.dateTime(FirestoreFields.startDate),
      endDate: wire.dateTime(FirestoreFields.endDate),
    );
  }

  static Map<String, dynamic> toMap(CalendarBlock entity) => {
    FirestoreFields.vehicleId: entity.vehicleId,
    FirestoreFields.startDate: Timestamp.fromDate(entity.startDate),
    FirestoreFields.endDate: Timestamp.fromDate(entity.endDate),
  };
}
