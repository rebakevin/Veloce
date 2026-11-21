import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:veloce/core/domain/entities/vehicle.dart';
import 'package:veloce/core/domain/entities/vehicle_document.dart';
import 'package:veloce/core/domain/enums/document_kind.dart';
import 'package:veloce/core/domain/enums/vehicle_status.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/error/result.dart';

import '../../domain/entities/document_input.dart';
import '../../domain/repositories/vehicle_repository.dart';
import '../../domain/rules/document_rules.dart';
import '../../domain/rules/document_status_rules.dart';
import '../../domain/usecases/set_status.dart';
import '../../domain/usecases/upsert_document.dart';

part 'documents_event.dart';
part 'documents_state.dart';

class DocumentsBloc extends Bloc<DocumentsEvent, DocumentsState> {
  DocumentsBloc({
    required this._vehicles,
    required this._upsertDocument,
    required this._setStatus,
    required this._clock,
  }) : super(const DocumentsLoading()) {
    on<DocumentsStarted>(_onStarted);
    on<DocumentSubmitted>(_onSubmitted);
    on<DocumentsResumeRequested>(_onResumeRequested);
  }

  final VehicleRepository _vehicles;
  final UpsertDocument _upsertDocument;
  final SetStatus _setStatus;
  final Clock _clock;

  Future<void> _onStarted(
    DocumentsStarted event,
    Emitter<DocumentsState> emit,
  ) async {
    emit(const DocumentsLoading());
    await emit.onEach<Result<Vehicle>>(
      _vehicles.watchVehicle(event.vehicleId),
      onData: (result) async {
        switch (result) {
          case Failure(:final failure):
            emit(DocumentsFailure(failure.message));
          case Success(:final value):
            await _load(value, emit);
        }
      },
    );
  }

  Future<void> _load(Vehicle vehicle, Emitter<DocumentsState> emit) async {
    final result = await _vehicles.documentsOf(vehicle.id);
    if (isClosed) return;
    switch (result) {
      case Failure(:final failure):
        emit(DocumentsFailure(failure.message));
      case Success(:final value):
        final current = state;
        final shown = await _pauseIfLapsed(vehicle);
        if (isClosed) return;
        emit(
          DocumentsLoaded(
            vehicle: shown,
            documents: value,
            expired: _expired(value),
            busy: current is DocumentsLoaded
                ? current.busy
                : DocumentsBusy.none,
            notice: current is DocumentsLoaded ? current.notice : null,
          ),
        );
    }
  }

  /// Nothing pauses a car when a paper expires, so do it when the owner opens
  /// the documents. Best effort: a failed write leaves the car as it was.
  Future<Vehicle> _pauseIfLapsed(Vehicle vehicle) async {
    if (!DocumentStatusRules.needsPausing(vehicle, now: _clock.now())) {
      return vehicle;
    }
    final result = await _setStatus(vehicle, VehicleStatus.paused);
    return result is Success<void>
        ? vehicle.copyWith(status: VehicleStatus.paused)
        : vehicle;
  }

  Future<void> _onSubmitted(
    DocumentSubmitted event,
    Emitter<DocumentsState> emit,
  ) async {
    final current = state;
    if (current is! DocumentsLoaded || current.busy != DocumentsBusy.none) {
      return;
    }
    emit(current.copyWith(busy: DocumentsBusy.saving, clearNotice: true));
    final result = await _upsertDocument(
      vehicle: current.vehicle,
      current: current.documents,
      input: event.input,
    );
    if (isClosed) return;
    final latest = _latest(current);
    switch (result) {
      case Failure(:final failure):
        emit(
          latest.copyWith(
            busy: DocumentsBusy.none,
            notice: DocumentsNotice(failure.message, isError: true),
          ),
        );
      case Success():
        final refreshed = await _vehicles.documentsOf(current.vehicle.id);
        if (isClosed) return;
        final documents = refreshed is Success<List<VehicleDocument>>
            ? refreshed.value
            : latest.documents;
        emit(
          _latest(current).copyWith(
            busy: DocumentsBusy.none,
            documents: documents,
            expired: _expired(documents),
            notice: const DocumentsNotice('Document saved.', isError: false),
          ),
        );
    }
  }

  Future<void> _onResumeRequested(
    DocumentsResumeRequested event,
    Emitter<DocumentsState> emit,
  ) async {
    final current = state;
    if (current is! DocumentsLoaded || current.busy != DocumentsBusy.none) {
      return;
    }
    emit(current.copyWith(busy: DocumentsBusy.resuming, clearNotice: true));
    final result = await _setStatus(current.vehicle, VehicleStatus.published);
    if (isClosed) return;
    final latest = _latest(current);
    emit(switch (result) {
      Failure(:final failure) => latest.copyWith(
        busy: DocumentsBusy.none,
        notice: DocumentsNotice(failure.message, isError: true),
      ),
      Success() => latest.copyWith(
        busy: DocumentsBusy.none,
        vehicle: latest.vehicle.copyWith(status: VehicleStatus.published),
        notice: const DocumentsNotice(
          'Your car is published again.',
          isError: false,
        ),
      ),
    });
  }

  /// The loaded state now, which a vehicle update may have changed while a
  /// write was running.
  DocumentsLoaded _latest(DocumentsLoaded fallback) {
    final now = state;
    return now is DocumentsLoaded ? now : fallback;
  }

  Set<DocumentKind> _expired(List<VehicleDocument> documents) =>
      DocumentStatusRules.expiredRequired(documents, now: _clock.now());
}
