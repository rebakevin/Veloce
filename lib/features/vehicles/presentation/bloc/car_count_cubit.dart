import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:veloce/core/domain/entities/vehicle.dart';
import 'package:veloce/core/domain/enums/vehicle_status.dart';
import 'package:veloce/core/error/result.dart';

import '../../domain/usecases/watch_owner_vehicles.dart';

sealed class CarCountState extends Equatable {
  const CarCountState();

  @override
  List<Object?> get props => [];
}

final class CarCountLoading extends CarCountState {
  const CarCountLoading();
}

final class CarCountLoaded extends CarCountState {
  const CarCountLoaded({required this.published, required this.paused});

  final int published;
  final int paused;

  @override
  List<Object?> get props => [published, paused];
}

final class CarCountFailure extends CarCountState {
  const CarCountFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class CarCountCubit extends Cubit<CarCountState> {
  CarCountCubit({required WatchOwnerVehicles watchVehicles})
    : super(const CarCountLoading()) {
    _subscription = watchVehicles().listen(_onResult);
  }

  late final StreamSubscription<Result<List<Vehicle>>> _subscription;

  void _onResult(Result<List<Vehicle>> result) {
    emit(
      result.when<CarCountState>(
        success: (vehicles) => CarCountLoaded(
          published: _count(vehicles, VehicleStatus.published),
          paused: _count(vehicles, VehicleStatus.paused),
        ),
        failure: (failure) => CarCountFailure(failure.message),
      ),
    );
  }

  int _count(List<Vehicle> vehicles, VehicleStatus status) =>
      vehicles.where((vehicle) => vehicle.status == status).length;

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
