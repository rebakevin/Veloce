import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';

import '../repositories/vehicle_repository.dart';
import '../rules/availability_rules.dart';

class SetAvailability {
  const SetAvailability(this._vehicles, this._clock);

  final VehicleRepository _vehicles;
  final Clock _clock;

  Future<Result<void>> call(
    String vehicleId,
    DateTime? from,
    DateTime? to,
  ) async {
    final bookings = await _vehicles.bookingsOf(vehicleId);
    switch (bookings) {
      case Failure(:final failure):
        return Result.failure(failure);
      case Success(:final value):
        final problem = AvailabilityRules.check(
          from: from,
          to: to,
          bookedDays: AvailabilityRules.bookedDays(value, now: _clock.now()),
        );
        if (problem != null) return Result.failure(ConflictFailure(problem));
        return _vehicles.setAvailability(vehicleId, from, to);
    }
  }
}
