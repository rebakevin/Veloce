import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/firestore_fields.dart';
import '../../constants/firestore_paths.dart';
import '../../domain/entities/audit_log_entry.dart';
import '../../domain/services/atomic_write.dart';
import '../../domain/services/audit_logger.dart';
import '../../domain/services/clock.dart';
import '../models/audit_log_entry_model.dart';

class FirestoreAuditLogger implements AuditLogger {
  const FirestoreAuditLogger(this._clock);

  final Clock _clock;

  @override
  void record(
    AtomicWrite write, {
    required String actorId,
    required String entityType,
    required String entityId,
    required String? oldState,
    required String newState,
  }) {
    final id = write.newId(FirestorePaths.auditLogs);
    final entry = AuditLogEntry(
      id: id,
      actorId: actorId,
      entityType: entityType,
      entityId: entityId,
      oldState: oldState,
      newState: newState,
      at: _clock.now(),
    );
    write.set(
      '${FirestorePaths.auditLogs}/$id',
      AuditLogEntryModel.toMap(entry)
        ..[FirestoreFields.at] = FieldValue.serverTimestamp(),
    );
  }
}
