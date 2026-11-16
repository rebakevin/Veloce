import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/features/vehicles/domain/rules/vehicle_removal_rules.dart';

import '../builders.dart';

void main() {
  final now = DateTime(2026, 11, 14);

  group('VehicleRemovalRules.check', () {
    test('no bookings allows removal', () {
      expect(VehicleRemovalRules.check([], now: now), isNull);
    });

    test('a pending booking blocks removal with a message', () {
      final bookings = [aBooking(expiresAt: DateTime(2026, 11, 20))];

      expect(VehicleRemovalRules.check(bookings, now: now), isNotNull);
    });

    test('a booking in return inspection blocks removal', () {
      final bookings = [aBooking(status: BookingStatus.returning)];

      expect(VehicleRemovalRules.check(bookings, now: now), isNotNull);
    });

    test('a pending booking past its deadline allows removal', () {
      final bookings = [aBooking(expiresAt: DateTime(2026, 11, 13))];

      expect(VehicleRemovalRules.check(bookings, now: now), isNull);
    });

    test('only finished bookings allow removal', () {
      final bookings = [
        aBooking(status: BookingStatus.completed),
        aBooking(status: BookingStatus.cancelled),
        aBooking(status: BookingStatus.declined),
      ];

      expect(VehicleRemovalRules.check(bookings, now: now), isNull);
    });
  });
}
