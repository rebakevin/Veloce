import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/error/result.dart';

import '../entities/availability_overview.dart';
import '../repositories/vehicle_repository.dart';
import '../rules/availability_rules.dart';

/// The car, kept live, with the days its open bookings lock.
class WatchAvailability {
  const WatchAvailability(this._vehicles, this._clock);

  final VehicleRepository _vehicles;
  final Clock _clock;

  Stream<Result<AvailabilityOverview>> call(String vehicleId) {
    return _vehicles.watchVehicle(vehicleId).asyncMap((vehicle) async {
      switch (vehicle) {
        case Failure(:final failure):
          return Result.failure(failure);
        case Success(value: final car):
          final bookings = await _vehicles.bookingsOf(vehicleId);
          return bookings.when(
            success: (list) => Result.success(
              AvailabilityOverview(
                vehicle: car,
                bookedDays: AvailabilityRules.bookedDays(
                  list,
                  now: _clock.now(),
                ),
              ),
            ),
            failure: Result<AvailabilityOverview>.failure,
          );
      }
    });
  }
}
