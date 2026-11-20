part of 'documents_bloc.dart';

enum DocumentsBusy { none, saving, resuming }

/// A message for the screen to show; replaced on the next action.
class DocumentsNotice extends Equatable {
  const DocumentsNotice(this.message, {required this.isError});

  final String message;
  final bool isError;

  @override
  List<Object?> get props => [message, isError];
}

sealed class DocumentsState extends Equatable {
  const DocumentsState();

  @override
  List<Object?> get props => [];
}

final class DocumentsLoading extends DocumentsState {
  const DocumentsLoading();
}

final class DocumentsFailure extends DocumentsState {
  const DocumentsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class DocumentsLoaded extends DocumentsState {
  const DocumentsLoaded({
    required this.vehicle,
    required this.documents,
    required this.expired,
    this.busy = DocumentsBusy.none,
    this.notice,
  });

  final Vehicle vehicle;
  final List<VehicleDocument> documents;

  /// Required papers whose expiry has passed.
  final Set<DocumentKind> expired;
  final DocumentsBusy busy;
  final DocumentsNotice? notice;

  bool get pausedByExpiry =>
      vehicle.status == VehicleStatus.paused && expired.isNotEmpty;

  /// A paused car whose required papers are all present and valid.
  bool get canResume =>
      vehicle.status == VehicleStatus.paused &&
      expired.isEmpty &&
      DocumentRules.missingRequired(documents).isEmpty;

  VehicleDocument? documentOf(DocumentKind kind) =>
      documents.where((document) => document.kind == kind).firstOrNull;

  DocumentsLoaded copyWith({
    Vehicle? vehicle,
    List<VehicleDocument>? documents,
    Set<DocumentKind>? expired,
    DocumentsBusy? busy,
    DocumentsNotice? notice,
    bool clearNotice = false,
  }) {
    return DocumentsLoaded(
      vehicle: vehicle ?? this.vehicle,
      documents: documents ?? this.documents,
      expired: expired ?? this.expired,
      busy: busy ?? this.busy,
      notice: clearNotice ? null : notice ?? this.notice,
    );
  }

  @override
  List<Object?> get props => [vehicle, documents, expired, busy, notice];
}
