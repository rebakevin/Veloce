import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';

import '../repositories/vehicle_repository.dart';
import '../rules/vehicle_removal_rules.dart';

class RemoveVehicle {
  const RemoveVehicle(this._vehicles, this._clock);

  final VehicleRepository _vehicles;
  final Clock _clock;

  Future<Result<void>> call(String vehicleId) async {
    final bookings = await _vehicles.bookingsOf(vehicleId);
    switch (bookings) {
      case Failure(:final failure):
        return Result.failure(failure);
      case Success(:final value):
        final problem = VehicleRemovalRules.check(value, now: _clock.now());
        if (problem != null) return Result.failure(ConflictFailure(problem));
        return _vehicles.remove(vehicleId);
    }
  }
}
