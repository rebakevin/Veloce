import 'package:bloc/bloc.dart';

import 'package:veloce/core/domain/enums/transmission.dart';
import 'package:veloce/core/domain/enums/vehicle_type.dart';

import '../../domain/entities/vehicle_filters.dart';

/// Edits the results filters. The active count and reset live here so the
/// results page and the filter form agree.
class FiltersCubit extends Cubit<VehicleFilters> {
  FiltersCubit([super.initial = VehicleFilters.none]);

  int get activeCount => state.activeCount;

  void minPriceChanged(int? value) {
    emit(
      value == null
          ? state.copyWith(clearMinPrice: true)
          : state.copyWith(minPrice: value),
    );
  }

  void maxPriceChanged(int? value) {
    emit(
      value == null
          ? state.copyWith(clearMaxPrice: true)
          : state.copyWith(maxPrice: value),
    );
  }

  void typeChanged(VehicleType? value) {
    emit(
      value == null
          ? state.copyWith(clearType: true)
          : state.copyWith(type: value),
    );
  }

  void transmissionChanged(Transmission? value) {
    emit(
      value == null
          ? state.copyWith(clearTransmission: true)
          : state.copyWith(transmission: value),
    );
  }

  void seatsChanged(int? value) {
    emit(
      value == null
          ? state.copyWith(clearMinSeats: true)
          : state.copyWith(minSeats: value),
    );
  }

  void reset() => emit(VehicleFilters.none);
}
