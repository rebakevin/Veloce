import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/features/vehicles/domain/entities/day_range.dart';
import 'package:veloce/features/vehicles/domain/rules/availability_rules.dart';

import '../builders.dart';

void main() {
  final now = DateTime(2026, 11, 14);
  final booked = [DayRange(DateTime(2026, 12, 1), DateTime(2026, 12, 5))];

  group('AvailabilityRules.bookedDays', () {
    test('keeps open bookings and drops finished ones', () {
      final days = AvailabilityRules.bookedDays([
        aBooking(status: BookingStatus.confirmed),
        aBooking(status: BookingStatus.completed),
        aBooking(status: BookingStatus.cancelled),
      ], now: now);

      expect(days, booked);
    });
  });

  group('AvailabilityRules.check', () {
    test('range covering every booked day is allowed', () {
      expect(
        AvailabilityRules.check(
          from: DateTime(2026, 11, 20),
          to: DateTime(2026, 12, 31),
          bookedDays: booked,
        ),
        isNull,
      );
    });

    test('range ending on the last booked day is allowed', () {
      expect(
        AvailabilityRules.check(
          from: DateTime(2026, 12, 1),
          to: DateTime(2026, 12, 5),
          bookedDays: booked,
        ),
        isNull,
      );
    });

    test('start after the end is refused', () {
      expect(
        AvailabilityRules.check(
          from: DateTime(2026, 12, 10),
          to: DateTime(2026, 12, 9),
          bookedDays: const [],
        ),
        isNotNull,
      );
    });

    test('range that starts after a booked day is refused', () {
      expect(
        AvailabilityRules.check(
          from: DateTime(2026, 12, 3),
          to: DateTime(2026, 12, 31),
          bookedDays: booked,
        ),
        contains('01/12/2026'),
      );
    });

    test('range that ends before a booked day is refused', () {
      expect(
        AvailabilityRules.check(
          from: DateTime(2026, 11, 20),
          to: DateTime(2026, 12, 4),
          bookedDays: booked,
        ),
        isNotNull,
      );
    });

    test('only one of the two dates is refused', () {
      expect(
        AvailabilityRules.check(
          from: DateTime(2026, 12, 1),
          to: null,
          bookedDays: const [],
        ),
        isNotNull,
      );
    });

    test('clearing is allowed without bookings and refused with them', () {
      expect(
        AvailabilityRules.check(from: null, to: null, bookedDays: const []),
        isNull,
      );
      expect(
        AvailabilityRules.check(from: null, to: null, bookedDays: booked),
        isNotNull,
      );
    });
  });
}
