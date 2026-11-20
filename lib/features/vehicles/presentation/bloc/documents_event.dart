part of 'documents_bloc.dart';

sealed class DocumentsEvent extends Equatable {
  const DocumentsEvent();

  @override
  List<Object?> get props => [];
}

final class DocumentsStarted extends DocumentsEvent {
  const DocumentsStarted(this.vehicleId);

  final String vehicleId;

  @override
  List<Object?> get props => [vehicleId];
}

final class DocumentSubmitted extends DocumentsEvent {
  const DocumentSubmitted(this.input);

  final DocumentInput input;

  @override
  List<Object?> get props => [input];
}

final class DocumentsResumeRequested extends DocumentsEvent {
  const DocumentsResumeRequested();
}
