import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/features/vehicles/domain/usecases/find_next_rentals.dart';

import '../builders.dart';

void main() {
  final clock = FixedClock(DateTime(2026, 11, 14));

  test('an open booking is the next rental of its car', () async {
    final repository = FakeVehicleRepository(
      bookings: [aBooking(status: BookingStatus.confirmed)],
    );

    final next = await FindNextRentals(repository, clock)([aVehicle()]);

    expect(next['car-1']?.id, 'booking-1');
  });

  test('finished bookings leave the car without a next rental', () async {
    final repository = FakeVehicleRepository(
      bookings: [aBooking(status: BookingStatus.completed)],
    );

    final next = await FindNextRentals(repository, clock)([aVehicle()]);

    expect(next, isEmpty);
  });

  test('a booking that already ended is not the next rental', () async {
    final repository = FakeVehicleRepository(
      bookings: [aBooking(status: BookingStatus.confirmed)],
    );

    final next = await FindNextRentals(repository, FixedClock(DateTime(2027)))([
      aVehicle(),
    ]);

    expect(next, isEmpty);
  });
}
