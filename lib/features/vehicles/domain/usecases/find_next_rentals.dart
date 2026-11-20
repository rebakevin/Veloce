import 'package:veloce/core/domain/entities/booking.dart';
import 'package:veloce/core/domain/entities/vehicle.dart';
import 'package:veloce/core/domain/services/booking_state_machine.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/error/result.dart';

import '../repositories/vehicle_repository.dart';

/// The next open booking of each car, keyed by vehicle id. Cars without one,
/// or whose bookings could not be read, are left out.
class FindNextRentals {
  const FindNextRentals(
    this._vehicles,
    this._clock, [
    this._machine = const BookingStateMachine(),
  ]);

  final VehicleRepository _vehicles;
  final Clock _clock;
  final BookingStateMachine _machine;

  Future<Map<String, Booking>> call(List<Vehicle> vehicles) async {
    final now = _clock.now();
    final today = DateTime(now.year, now.month, now.day);
    final next = <String, Booking>{};
    for (final vehicle in vehicles) {
      final result = await _vehicles.bookingsOf(vehicle.id);
      if (result is! Success<List<Booking>>) continue;
      final open =
          result.value
              .where(
                (booking) =>
                    !_machine.isTerminal(
                      _machine.effectiveStatus(booking, now: now),
                    ) &&
                    !booking.endDate.isBefore(today),
              )
              .toList()
            ..sort((a, b) => a.startDate.compareTo(b.startDate));
      if (open.isNotEmpty) next[vehicle.id] = open.first;
    }
    return next;
  }
}
