import 'package:equatable/equatable.dart';

/// Append-only record of a state change.
class AuditLogEntry extends Equatable {
  const AuditLogEntry({
    required this.id,
    required this.actorId,
    required this.entityType,
    required this.entityId,
    required this.oldState,
    required this.newState,
    required this.at,
  });

  final String id;
  final String actorId;
  final String entityType;
  final String entityId;
  final String? oldState;
  final String newState;
  final DateTime at;

  AuditLogEntry copyWith({
    String? id,
    String? actorId,
    String? entityType,
    String? entityId,
    String? oldState,
    String? newState,
    DateTime? at,
  }) {
    return AuditLogEntry(
      id: id ?? this.id,
      actorId: actorId ?? this.actorId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      oldState: oldState ?? this.oldState,
      newState: newState ?? this.newState,
      at: at ?? this.at,
    );
  }

  @override
  List<Object?> get props => [
    id,
    actorId,
    entityType,
    entityId,
    oldState,
    newState,
    at,
  ];
}
