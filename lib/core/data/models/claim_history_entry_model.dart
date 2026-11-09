import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/firestore_fields.dart';
import '../../domain/entities/claim_history_entry.dart';
import '../../domain/enums/claim_response.dart';
import 'wire.dart';

/// Maps [ClaimHistoryEntry] to and from the Firestore wire map.
abstract final class ClaimHistoryEntryModel {
  static ClaimHistoryEntry fromMap(Map<String, dynamic> map) {
    final wire = WireReader('ClaimHistoryEntry', map);
    return ClaimHistoryEntry(
      amount: wire.integer(FirestoreFields.amount),
      reason: wire.string(FirestoreFields.reason),
      at: wire.dateTime(FirestoreFields.at),
      response: wire.enumValue(FirestoreFields.response, ClaimResponse.fromKey),
    );
  }

  static Map<String, dynamic> toMap(ClaimHistoryEntry entity) => {
    FirestoreFields.amount: entity.amount,
    FirestoreFields.reason: entity.reason,
    FirestoreFields.at: Timestamp.fromDate(entity.at),
    FirestoreFields.response: entity.response.key,
  };
}
