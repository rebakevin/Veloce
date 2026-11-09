import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/entities/renter_lock.dart';
import 'package:veloce/core/domain/enums/booking_actor.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/domain/services/booking_state_machine.dart';

import '../../support/builders.dart';

void main() {
  const machine = BookingStateMachine();

  group('canTransition', () {
    test('only the owner approves or declines a pending request', () {
      expect(
        machine.canTransition(
          BookingStatus.pending,
          BookingStatus.approved,
          BookingActor.owner,
        ),
        isTrue,
      );
      expect(
        machine.canTransition(
          BookingStatus.pending,
          BookingStatus.approved,
          BookingActor.renter,
        ),
        isFalse,
      );
    });

    test('only the renter confirms by paying', () {
      expect(
        machine.canTransition(
          BookingStatus.approved,
          BookingStatus.confirmed,
          BookingActor.renter,
        ),
        isTrue,
      );
      expect(
        machine.canTransition(
          BookingStatus.approved,
          BookingStatus.confirmed,
          BookingActor.owner,
        ),
        isFalse,
      );
    });

    test('skipping a step is rejected', () {
      expect(
        machine.canTransition(
          BookingStatus.pending,
          BookingStatus.confirmed,
          BookingActor.owner,
        ),
        isFalse,
      );
      expect(
        machine.canTransition(
          BookingStatus.confirmed,
          BookingStatus.completed,
          BookingActor.owner,
        ),
        isFalse,
      );
    });

    test('terminal statuses cannot move', () {
      for (final status in [
        BookingStatus.declined,
        BookingStatus.cancelled,
        BookingStatus.expired,
        BookingStatus.completed,
      ]) {
        expect(machine.isTerminal(status), isTrue, reason: status.key);
      }
      expect(machine.isTerminal(BookingStatus.active), isFalse);
    });
  });

  group('effectiveStatus', () {
    final deadline = testNow.add(const Duration(hours: 24));

    test('a pending request past expiresAt reads as expired', () {
      final booking = aBooking(expiresAt: deadline);
      expect(
        machine.effectiveStatus(
          booking,
          now: deadline.add(const Duration(minutes: 1)),
        ),
        BookingStatus.expired,
      );
      expect(
        machine.effectiveStatus(booking, now: testNow),
        BookingStatus.pending,
      );
    });

    test('an approved booking past payDeadline reads as expired', () {
      final booking = aBooking(
        status: BookingStatus.approved,
        payDeadline: deadline,
      );
      expect(
        machine.effectiveStatus(
          booking,
          now: deadline.add(const Duration(minutes: 1)),
        ),
        BookingStatus.expired,
      );
    });

    test('a lock on another booking cancels open requests only', () {
      final lock = RenterLock(
        renterId: 'renter-1',
        bookingId: 'other',
        createdAt: testNow,
      );
      expect(
        machine.effectiveStatus(aBooking(), now: testNow, renterLock: lock),
        BookingStatus.cancelled,
      );
      expect(
        machine.effectiveStatus(
          aBooking(status: BookingStatus.confirmed),
          now: testNow,
          renterLock: lock,
        ),
        BookingStatus.confirmed,
      );
    });

    test('the booking that owns the lock keeps its status', () {
      final lock = RenterLock(
        renterId: 'renter-1',
        bookingId: 'booking-1',
        createdAt: testNow,
      );
      expect(
        machine.effectiveStatus(
          aBooking(status: BookingStatus.approved),
          now: testNow,
          renterLock: lock,
        ),
        BookingStatus.approved,
      );
    });
  });
}
