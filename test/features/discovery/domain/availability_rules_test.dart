import 'package:flutter_test/flutter_test.dart';

import 'package:veloce/core/domain/entities/calendar_block.dart';
import 'package:veloce/core/domain/enums/transmission.dart';
import 'package:veloce/core/domain/enums/vehicle_type.dart';
import 'package:veloce/features/discovery/domain/entities/vehicle_filters.dart';
import 'package:veloce/features/discovery/domain/services/availability_rules.dart';

import '../../../support/builders.dart';

DateTime day(int offset) =>
    DateTime(testNow.year, testNow.month, testNow.day + offset);

CalendarBlock block(int start, int end) => CalendarBlock(
  bookingId: 'booking-1',
  vehicleId: 'car-1',
  startDate: day(start),
  endDate: day(end),
);

void main() {
  const rules = AvailabilityRules();

  group('availability window', () {
    test('accepts a range inside the owner window', () {
      final vehicle = aVehicle(availableFrom: day(0), availableTo: day(10));
      expect(rules.isWithinWindow(vehicle, day(0), day(3)), isTrue);
      expect(rules.isWithinWindow(vehicle, day(7), day(10)), isTrue);
    });

    test('rejects a range before or after the window', () {
      final vehicle = aVehicle(availableFrom: day(5), availableTo: day(9));
      expect(rules.isWithinWindow(vehicle, day(4), day(8)), isFalse);
      expect(rules.isWithinWindow(vehicle, day(6), day(10)), isFalse);
      expect(rules.isWithinWindow(vehicle, day(5), day(9)), isTrue);
    });

    test('rejects a past pickup day', () {
      expect(rules.isPast(day(-1), testNow), isTrue);
      expect(rules.isPast(day(0), testNow), isFalse);
    });
  });

  group('calendar blocks', () {
    test('a block ending on the pickup day does not overlap', () {
      expect(rules.blockOverlaps(block(2, 4), day(4), day(6)), isFalse);
    });

    test('a block starting on the return day does not overlap', () {
      expect(rules.blockOverlaps(block(4, 6), day(2), day(4)), isFalse);
    });

    test('a block inside or crossing the range overlaps', () {
      expect(rules.blockOverlaps(block(2, 4), day(1), day(3)), isTrue);
      expect(rules.blockOverlaps(block(2, 4), day(2), day(4)), isTrue);
      expect(rules.blockOverlaps(block(2, 4), day(3), day(5)), isTrue);
    });

    test('isFree is true only when every block is clear of the range', () {
      final blocks = [block(2, 4), block(8, 9)];
      expect(rules.isFree(blocks, day(0), day(2)), isTrue);
      expect(rules.isFree(blocks, day(1), day(3)), isFalse);
      expect(rules.isFree(blocks, day(4), day(8)), isTrue);
    });
  });

  group('documents and filters', () {
    test('documents are valid through their expiry day', () {
      expect(
        rules.hasValidDocs(aVehicle(docsValidUntil: day(0)), testNow),
        isTrue,
      );
      expect(
        rules.hasValidDocs(aVehicle(docsValidUntil: day(-1)), testNow),
        isFalse,
      );
    });

    test('filters combine price, type, transmission and seats', () {
      final car = aVehicle(
        dailyPrice: 60000,
        type: VehicleType.suv,
        transmission: Transmission.manual,
        seats: 7,
      );
      const filters = VehicleFilters(
        minPrice: 50000,
        maxPrice: 70000,
        type: VehicleType.suv,
        transmission: Transmission.manual,
        minSeats: 7,
      );
      expect(filters.matches(car), isTrue);
      expect(filters.activeCount, 5);
      expect(filters.copyWith(type: VehicleType.sedan).matches(car), isFalse);
      expect(filters.copyWith(minPrice: 61000).matches(car), isFalse);
      expect(filters.copyWith(minSeats: 8).matches(car), isFalse);
    });
  });

  group('combined availability', () {
    test('requires a future date, the window and no block', () {
      final vehicle = aVehicle(availableFrom: day(0), availableTo: day(10));
      expect(
        rules.isAvailable(
          vehicle: vehicle,
          blocks: const [],
          start: day(1),
          end: day(3),
          now: testNow,
        ),
        isTrue,
      );
      expect(
        rules.isAvailable(
          vehicle: vehicle,
          blocks: [block(2, 4)],
          start: day(1),
          end: day(3),
          now: testNow,
        ),
        isFalse,
      );
      expect(
        rules.isAvailable(
          vehicle: vehicle,
          blocks: const [],
          start: day(-1),
          end: day(1),
          now: testNow,
        ),
        isFalse,
      );
    });
  });
}
