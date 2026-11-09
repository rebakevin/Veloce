import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/firestore_fields.dart';
import '../../domain/entities/repair_expense.dart';
import 'wire.dart';

/// Maps [RepairExpense] to and from the Firestore wire map.
abstract final class RepairExpenseModel {
  static RepairExpense fromMap(String docId, Map<String, dynamic> map) {
    final wire = WireReader('RepairExpense', map);
    return RepairExpense(
      id: docId,
      bookingId: wire.string(FirestoreFields.bookingId),
      vehicleId: wire.string(FirestoreFields.vehicleId),
      ownerId: wire.string(FirestoreFields.ownerId),
      amount: wire.integer(FirestoreFields.amount),
      description: wire.string(FirestoreFields.description),
      receiptUrl: wire.optionalString(FirestoreFields.receiptUrl),
      createdAt: wire.dateTime(FirestoreFields.createdAt),
    );
  }

  static Map<String, dynamic> toMap(RepairExpense entity) => {
    FirestoreFields.bookingId: entity.bookingId,
    FirestoreFields.vehicleId: entity.vehicleId,
    FirestoreFields.ownerId: entity.ownerId,
    FirestoreFields.amount: entity.amount,
    FirestoreFields.description: entity.description,
    FirestoreFields.receiptUrl: entity.receiptUrl,
    FirestoreFields.createdAt: Timestamp.fromDate(entity.createdAt),
  };
}
