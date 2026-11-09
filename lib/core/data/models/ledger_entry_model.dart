import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/firestore_fields.dart';
import '../../domain/entities/ledger_entry.dart';
import '../../domain/enums/party.dart';
import '../../domain/enums/transaction_status.dart';
import '../../domain/enums/transaction_type.dart';
import 'wire.dart';

/// Maps [LedgerEntry] to and from the Firestore wire map.
abstract final class LedgerEntryModel {
  static LedgerEntry fromMap(String docId, Map<String, dynamic> map) {
    final wire = WireReader('LedgerEntry', map);
    return LedgerEntry(
      id: docId,
      bookingId: wire.string(FirestoreFields.bookingId),
      vehicleId: wire.string(FirestoreFields.vehicleId),
      ownerId: wire.string(FirestoreFields.ownerId),
      renterId: wire.string(FirestoreFields.renterId),
      type: wire.enumValue(FirestoreFields.type, TransactionType.fromKey),
      amount: wire.integer(FirestoreFields.amount),
      fromParty: wire.enumValue(FirestoreFields.fromParty, Party.fromKey),
      toParty: wire.enumValue(FirestoreFields.toParty, Party.fromKey),
      reference: wire.string(FirestoreFields.reference),
      status: wire.enumValue(FirestoreFields.status, TransactionStatus.fromKey),
      at: wire.dateTime(FirestoreFields.at),
    );
  }

  static Map<String, dynamic> toMap(LedgerEntry entity) => {
    FirestoreFields.bookingId: entity.bookingId,
    FirestoreFields.vehicleId: entity.vehicleId,
    FirestoreFields.ownerId: entity.ownerId,
    FirestoreFields.renterId: entity.renterId,
    FirestoreFields.type: entity.type.key,
    FirestoreFields.amount: entity.amount,
    FirestoreFields.fromParty: entity.fromParty.key,
    FirestoreFields.toParty: entity.toParty.key,
    FirestoreFields.reference: entity.reference,
    FirestoreFields.status: entity.status.key,
    FirestoreFields.at: Timestamp.fromDate(entity.at),
  };
}
