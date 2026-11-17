import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:veloce/core/domain/entities/vehicle.dart';
import 'package:veloce/core/domain/enums/vehicle_status.dart';
import 'package:veloce/core/error/result.dart';

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
  }) : super(const MyCarsLoading()) {
    on<MyCarsStarted>(_onStarted);
    on<MyCarsStatusToggled>(_onStatusToggled);
    on<MyCarsRemoveRequested>(_onRemoveRequested);
    on<MyCarsNoticeCleared>(_onNoticeCleared);
  }

  final WatchOwnerVehicles _watchVehicles;
  final SetStatus _setStatus;
  final RemoveVehicle _removeVehicle;

  Future<void> _onStarted(MyCarsStarted event, Emitter<MyCarsState> emit) {
    emit(const MyCarsLoading());
    return emit.forEach<Result<List<Vehicle>>>(
      _watchVehicles(),
      onData: (result) => result.when<MyCarsState>(
        success: (vehicles) =>
            vehicles.isEmpty ? const MyCarsEmpty() : MyCarsLoaded(vehicles),
        failure: (failure) => MyCarsFailure(failure.message),
      ),
    );
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
      emit(MyCarsLoaded(current.vehicles));
    }
  }

  void _showFailure(Result<void> result, Emitter<MyCarsState> emit) {
    final current = state;
    if (current is! MyCarsLoaded) return;
    if (result case Failure<void>(:final failure)) {
      emit(MyCarsLoaded(current.vehicles, notice: failure.message));
    }
  }
}
