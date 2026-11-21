import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:veloce/core/domain/entities/booking.dart';
import 'package:veloce/core/domain/entities/vehicle.dart';
import 'package:veloce/core/domain/enums/vehicle_status.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/error/result.dart';

import '../../domain/rules/document_status_rules.dart';
import '../../domain/usecases/find_next_rentals.dart';
import '../../domain/usecases/find_primary_photos.dart';
import '../../domain/usecases/remove_vehicle.dart';
import '../../domain/usecases/set_status.dart';
import '../../domain/usecases/watch_owner_vehicles.dart';

part 'my_cars_event.dart';
part 'my_cars_state.dart';

class MyCarsBloc extends Bloc<MyCarsEvent, MyCarsState> {
  MyCarsBloc({
    required this._watchVehicles,
    required this._setStatus,
    required this._removeVehicle,
    required this._findNextRentals,
    required this._findPrimaryPhotos,
    required this._clock,
  }) : super(const MyCarsLoading()) {
    on<MyCarsStarted>(_onStarted);
    on<MyCarsStatusToggled>(_onStatusToggled);
    on<MyCarsRemoveRequested>(_onRemoveRequested);
    on<MyCarsNoticeCleared>(_onNoticeCleared);
    on<MyCarsRefreshRequested>(_onRefreshRequested);
  }

  final WatchOwnerVehicles _watchVehicles;
  final SetStatus _setStatus;
  final RemoveVehicle _removeVehicle;
  final FindNextRentals _findNextRentals;
  final FindPrimaryPhotos _findPrimaryPhotos;
  final Clock _clock;

  Future<void> _onStarted(MyCarsStarted event, Emitter<MyCarsState> emit) {
    emit(const MyCarsLoading());
    return emit.forEach<MyCarsState>(
      _watchVehicles().asyncMap(_toState),
      onData: (state) => state,
    );
  }

  Future<MyCarsState> _toState(Result<List<Vehicle>> result) async {
    switch (result) {
      case Failure(:final failure):
        return MyCarsFailure(failure.message);
      case Success(:final value):
        if (value.isEmpty) return const MyCarsEmpty();
        return _load(await _pauseLapsed(value), reuse: _lastLoaded);
    }
  }

  /// Last loaded state, kept so a stream emission that did not change the set
  /// of cars skips the per-car rental and photo reads.
  MyCarsLoaded? _lastLoaded;

  /// Pauses cars whose papers lapsed while they were still published, so the
  /// listing status matches what search already hides. Best effort: the
  /// stream re-emits once the write lands.
  Future<List<Vehicle>> _pauseLapsed(List<Vehicle> vehicles) async {
    final now = _clock.now();
    final lapsed = vehicles
        .where((v) => DocumentStatusRules.needsPausing(v, now: now))
        .toList();
    if (lapsed.isEmpty) return vehicles;
    final results = await Future.wait([
      for (final vehicle in lapsed) _setStatus(vehicle, VehicleStatus.paused),
    ]);
    // Only show a car as paused when the write really landed.
    final paused = <String>{
      for (var i = 0; i < lapsed.length; i++)
        if (results[i] is Success<void>) lapsed[i].id,
    };
    return [
      for (final vehicle in vehicles)
        paused.contains(vehicle.id)
            ? vehicle.copyWith(status: VehicleStatus.paused)
            : vehicle,
    ];
  }

  Future<MyCarsLoaded> _load(
    List<Vehicle> vehicles, {
    MyCarsLoaded? reuse,
    int refreshCount = 0,
  }) async {
    final now = _clock.now();
    final sameCars =
        reuse != null &&
        reuse.vehicles.length == vehicles.length &&
        reuse.vehicles
            .map((v) => v.id)
            .toSet()
            .containsAll(vehicles.map((v) => v.id));
    final (rentals, photos) = sameCars
        ? (reuse.nextRentals, reuse.primaryPhotos)
        : await (_findNextRentals(vehicles), _findPrimaryPhotos(vehicles)).wait;
    return _lastLoaded = MyCarsLoaded(
      vehicles,
      refreshCount: refreshCount,
      nextRentals: rentals,
      primaryPhotos: photos,
      expiredIds: {
        for (final vehicle in vehicles)
          if (DocumentStatusRules.hasLapsed(vehicle, now: now)) vehicle.id,
      },
    );
  }

  Future<void> _onRefreshRequested(
    MyCarsRefreshRequested event,
    Emitter<MyCarsState> emit,
  ) async {
    final current = state;
    if (current is! MyCarsLoaded) return;
    final refreshed = await _load(
      current.vehicles,
      refreshCount: current.refreshCount + 1,
    );
    if (isClosed) return;
    emit(refreshed);
  }

  Future<void> _onStatusToggled(
    MyCarsStatusToggled event,
    Emitter<MyCarsState> emit,
  ) async {
    final next = event.vehicle.status == VehicleStatus.published
        ? VehicleStatus.paused
        : VehicleStatus.published;
    final result = await _setStatus(event.vehicle, next);
    if (isClosed) return;
    _showFailure(result, emit);
  }

  Future<void> _onRemoveRequested(
    MyCarsRemoveRequested event,
    Emitter<MyCarsState> emit,
  ) async {
    final result = await _removeVehicle(event.vehicleId);
    if (isClosed) return;
    _showFailure(result, emit);
  }

  void _onNoticeCleared(MyCarsNoticeCleared event, Emitter<MyCarsState> emit) {
    final current = state;
    if (current is MyCarsLoaded && current.notice != null) {
      emit(current.withoutNotice());
    }
  }

  void _showFailure(Result<void> result, Emitter<MyCarsState> emit) {
    final current = state;
    if (current is! MyCarsLoaded) return;
    if (result case Failure<void>(:final failure)) {
      emit(current.withNotice(failure.message));
    }
  }
}
