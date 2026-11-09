import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/firestore_fields.dart';
import '../../domain/entities/audit_log_entry.dart';
import 'wire.dart';

/// Maps [AuditLogEntry] to and from the Firestore wire map.
abstract final class AuditLogEntryModel {
  static AuditLogEntry fromMap(String docId, Map<String, dynamic> map) {
    final wire = WireReader('AuditLogEntry', map);
    return AuditLogEntry(
      id: docId,
      actorId: wire.string(FirestoreFields.actorId),
      entityType: wire.string(FirestoreFields.entityType),
      entityId: wire.string(FirestoreFields.entityId),
      oldState: wire.optionalString(FirestoreFields.oldState),
      newState: wire.string(FirestoreFields.newState),
      at: wire.dateTime(FirestoreFields.at),
    );
  }

  static Map<String, dynamic> toMap(AuditLogEntry entity) => {
    FirestoreFields.actorId: entity.actorId,
    FirestoreFields.entityType: entity.entityType,
    FirestoreFields.entityId: entity.entityId,
    FirestoreFields.oldState: entity.oldState,
    FirestoreFields.newState: entity.newState,
    FirestoreFields.at: Timestamp.fromDate(entity.at),
  };
}
