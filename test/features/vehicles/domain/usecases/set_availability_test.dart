import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/vehicles/domain/usecases/set_availability.dart';

import '../builders.dart';

void main() {
  final clock = FixedClock(DateTime(2026, 11, 14));

  group('SetAvailability', () {
    test('valid range is saved', () async {
      final repository = FakeVehicleRepository();

      final result = await SetAvailability(repository, clock)(
        'car-1',
        DateTime(2026, 11, 20),
        DateTime(2026, 12, 31),
      );

      expect(result, isA<Success<void>>());
      expect(repository.availability['car-1'], (
        DateTime(2026, 11, 20),
        DateTime(2026, 12, 31),
      ));
    });

    test('range dropping a booked day is refused and saves nothing', () async {
      final repository = FakeVehicleRepository(
        bookings: [aBooking(status: BookingStatus.confirmed)],
      );

      final result = await SetAvailability(repository, clock)(
        'car-1',
        DateTime(2026, 12, 3),
        DateTime(2026, 12, 31),
      );

      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).failure, isA<ConflictFailure>());
      expect(repository.availability, isEmpty);
    });

    test('finished booking does not lock its days', () async {
      final repository = FakeVehicleRepository(
        bookings: [aBooking(status: BookingStatus.completed)],
      );

      final result = await SetAvailability(repository, clock)(
        'car-1',
        DateTime(2026, 12, 10),
        DateTime(2026, 12, 31),
      );

      expect(result, isA<Success<void>>());
    });

    test('start after end is refused', () async {
      final repository = FakeVehicleRepository();

      final result = await SetAvailability(repository, clock)(
        'car-1',
        DateTime(2026, 12, 31),
        DateTime(2026, 12, 1),
      );

      expect(result, isA<Failure<void>>());
      expect(repository.availability, isEmpty);
    });
  });
}
