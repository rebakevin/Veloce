import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/entities/booking.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/features/vehicles/domain/rules/vehicle_removal_rules.dart';

Booking aBooking({
  BookingStatus status = BookingStatus.pending,
  DateTime? expiresAt,
}) {
  return Booking(
    id: 'booking-1',
    reference: 'REF-1',
    vehicleId: 'car-1',
    renterId: 'renter-1',
    ownerId: 'owner-1',
    startDate: DateTime(2026, 12, 1),
    endDate: DateTime(2026, 12, 5),
    days: 4,
    dailyRateApplied: 50000,
    rentalFee: 200000,
    cautionFee: 0,
    platformFee: 2000,
    totalPayable: 202000,
    status: status,
    reason: null,
    payDeadline: null,
    expiresAt: expiresAt,
    agreementAckAt: null,
    ownerPickupConfirmedAt: null,
    renterPickupConfirmedAt: null,
    returnedAt: null,
    ownerReturnConfirmedAt: null,
    renterReturnConfirmedAt: null,
    lateDays: 0,
    lateFee: 0,
    lateFeeWaived: false,
    cautionDecision: null,
    renterOutcomeAckAt: null,
    completedAt: null,
    createdAt: DateTime(2026, 11, 1),
    updatedAt: DateTime(2026, 11, 1),
  );
}

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
