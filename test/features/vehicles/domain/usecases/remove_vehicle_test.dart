import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/vehicles/domain/usecases/remove_vehicle.dart';

import '../builders.dart';

void main() {
  final clock = FixedClock(DateTime(2026, 11, 14));

  group('RemoveVehicle', () {
    test('open booking fails and removes nothing', () async {
      final repository = FakeVehicleRepository(
        bookings: [aBooking(status: BookingStatus.active)],
      );

      final result = await RemoveVehicle(repository, clock)('car-1');

      expect(result, isA<Failure<void>>());
      expect(repository.removed, isEmpty);
    });

    test('no bookings removes the car', () async {
      final repository = FakeVehicleRepository();

      final result = await RemoveVehicle(repository, clock)('car-1');

      expect(result, isA<Success<void>>());
      expect(repository.removed, ['car-1']);
    });

    test('only finished bookings removes the car', () async {
      final repository = FakeVehicleRepository(
        bookings: [aBooking(status: BookingStatus.completed)],
      );

      final result = await RemoveVehicle(repository, clock)('car-1');

      expect(result, isA<Success<void>>());
      expect(repository.removed, ['car-1']);
    });
  });
}
