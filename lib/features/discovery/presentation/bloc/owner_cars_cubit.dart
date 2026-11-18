import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:veloce/core/error/app_failure.dart';

import '../../domain/entities/vehicle_card_data.dart';
import '../../domain/repositories/search_repository.dart';

sealed class OwnerCarsState extends Equatable {
  const OwnerCarsState();

  @override
  List<Object?> get props => const [];
}

final class OwnerCarsLoading extends OwnerCarsState {
  const OwnerCarsLoading();
}

final class OwnerCarsEmpty extends OwnerCarsState {
  const OwnerCarsEmpty();

  @override
  List<Object?> get props => [];
}

final class OwnerCarsLoaded extends OwnerCarsState {
  const OwnerCarsLoaded(this.cars);

  final List<VehicleCardData> cars;

  @override
  List<Object?> get props => [cars];
}

final class OwnerCarsFailure extends OwnerCarsState {
  const OwnerCarsFailure(this.error);

  final AppFailure error;

  @override
  List<Object?> get props => [error];
}

/// Published cars for the public profile slot.
class OwnerCarsCubit extends Cubit<OwnerCarsState> {
  OwnerCarsCubit({required this._repository, required this.ownerId})
    : super(const OwnerCarsLoading());

  final SearchRepository _repository;
  final String ownerId;

  Future<void> load() async {
    emit(const OwnerCarsLoading());
    final result = await _repository.ownerCars(ownerId);
    if (isClosed) return;
    result.when(
      success: (cars) =>
          emit(cars.isEmpty ? const OwnerCarsEmpty() : OwnerCarsLoaded(cars)),
      failure: (failure) => emit(OwnerCarsFailure(failure)),
    );
  }
}
