import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/firestore_fields.dart';
import '../../domain/entities/caution_claim.dart';
import '../../domain/enums/claim_response.dart';
import '../../domain/enums/claim_status.dart';
import 'claim_history_entry_model.dart';
import 'wire.dart';

/// Maps [CautionClaim] to and from the Firestore wire map.
abstract final class CautionClaimModel {
  static CautionClaim fromMap(String docId, Map<String, dynamic> map) {
    final wire = WireReader('CautionClaim', map);
    return CautionClaim(
      bookingId: docId,
      originalAmount: wire.integer(FirestoreFields.originalAmount),
      currentAmount: wire.integer(FirestoreFields.currentAmount),
      reason: wire.string(FirestoreFields.reason),
      evidenceUrls: wire.stringList(FirestoreFields.evidenceUrls),
      renterResponse: wire.enumValue(
        FirestoreFields.renterResponse,
        ClaimResponse.fromKey,
      ),
      history: wire
          .mapList(FirestoreFields.history)
          .map(ClaimHistoryEntryModel.fromMap)
          .toList(),
      status: wire.enumValue(FirestoreFields.status, ClaimStatus.fromKey),
      updatedAt: wire.dateTime(FirestoreFields.updatedAt),
    );
  }

  static Map<String, dynamic> toMap(CautionClaim entity) => {
    FirestoreFields.originalAmount: entity.originalAmount,
    FirestoreFields.currentAmount: entity.currentAmount,
    FirestoreFields.reason: entity.reason,
    FirestoreFields.evidenceUrls: entity.evidenceUrls,
    FirestoreFields.renterResponse: entity.renterResponse.key,
    FirestoreFields.history: entity.history
        .map(ClaimHistoryEntryModel.toMap)
        .toList(),
    FirestoreFields.status: entity.status.key,
    FirestoreFields.updatedAt: Timestamp.fromDate(entity.updatedAt),
  };
}
