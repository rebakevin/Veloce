import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/features/booking/domain/services/booking_overlap.dart';

import '../../../support/builders.dart';

void main() {
  const overlap = BookingOverlap();
  final target = aBooking(status: BookingStatus.pending).copyWith(
    startDate: DateTime(2026, 11, 10),
    endDate: DateTime(2026, 11, 13),
  );

  test('overlapping ranges are detected, touching ones are not', () {
    expect(
      overlap.overlaps(
        start: DateTime(2026, 11, 10),
        end: DateTime(2026, 11, 13),
        otherStart: DateTime(2026, 11, 12),
        otherEnd: DateTime(2026, 11, 15),
      ),
      isTrue,
    );
    expect(
      overlap.overlaps(
        start: DateTime(2026, 11, 10),
        end: DateTime(2026, 11, 13),
        otherStart: DateTime(2026, 11, 13),
        otherEnd: DateTime(2026, 11, 15),
      ),
      isFalse,
    );
  });

  test('only other pending requests on the same car are returned', () {
    final overlapping = aBooking(status: BookingStatus.pending).copyWith(
      id: 'overlapping',
      startDate: DateTime(2026, 11, 12),
      endDate: DateTime(2026, 11, 14),
    );
    final later = aBooking(status: BookingStatus.pending).copyWith(
      id: 'later',
      startDate: DateTime(2026, 11, 20),
      endDate: DateTime(2026, 11, 22),
    );
    final otherCar = aBooking(status: BookingStatus.pending).copyWith(
      id: 'other-car',
      vehicleId: 'car-2',
      startDate: DateTime(2026, 11, 11),
      endDate: DateTime(2026, 11, 12),
    );
    final declined = aBooking(status: BookingStatus.declined).copyWith(
      id: 'declined',
      startDate: DateTime(2026, 11, 11),
      endDate: DateTime(2026, 11, 12),
    );

    final result = overlap.pendingOverlaps(target, [
      target,
      overlapping,
      later,
      otherCar,
      declined,
    ]);

    expect(result.map((booking) => booking.id), ['overlapping']);
  });
}
