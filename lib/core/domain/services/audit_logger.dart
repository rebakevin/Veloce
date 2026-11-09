import 'atomic_write.dart';

/// Appends an audit entry for a state change inside an [AtomicWrite].
abstract interface class AuditLogger {
  void record(
    AtomicWrite write, {
    required String actorId,
    required String entityType,
    required String entityId,
    required String? oldState,
    required String newState,
  });
}
