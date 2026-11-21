import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/features/booking/domain/services/expiry_engine.dart';

import '../../../support/builders.dart';

void main() {
  const engine = ExpiryEngine();
  final now = DateTime(2026, 11, 10, 12);

  test('the payment deadline is the earlier of 24 h and end of pickup day', () {
    final after24h = now.add(const Duration(hours: 24));
    expect(
      engine.paymentDeadline(approvedAt: now, pickupAt: DateTime(2026, 11, 15)),
      after24h,
    );
    // Pickup the next day: the day's end (36 h away) is later than 24 h.
    expect(
      engine.paymentDeadline(approvedAt: now, pickupAt: DateTime(2026, 11, 11)),
      after24h,
    );
  });

  test('a same-day pickup can still be paid until the day ends', () {
    final deadline = engine.paymentDeadline(
      approvedAt: now,
      pickupAt: DateTime(2026, 11, 10),
    );
    expect(deadline, DateTime(2026, 11, 11));
    expect(deadline.isAfter(now), isTrue);
  });

  test('approved late on the pickup day gives a short window', () {
    final late = DateTime(2026, 11, 10, 23, 30);
    final deadline = engine.paymentDeadline(
      approvedAt: late,
      pickupAt: DateTime(2026, 11, 10),
    );
    expect(deadline, DateTime(2026, 11, 11));
  });

  test('the reminder window opens shortly before the payment deadline', () {
    final soon = aBooking(
      status: BookingStatus.approved,
      payDeadline: now.add(const Duration(hours: 5)),
    );
    final far = aBooking(
      status: BookingStatus.approved,
      payDeadline: now.add(const Duration(hours: 20)),
    );
    final past = aBooking(
      status: BookingStatus.approved,
      payDeadline: now.subtract(const Duration(minutes: 1)),
    );
    expect(engine.isPaymentDeadlineNear(soon, now), isTrue);
    expect(engine.isPaymentDeadlineNear(far, now), isFalse);
    expect(engine.isPaymentDeadlineNear(past, now), isFalse);
  });

  test('pending requests expire after expiresAt', () {
    final booking = aBooking(
      expiresAt: now.subtract(const Duration(minutes: 1)),
    );
    expect(engine.isPendingExpired(booking, now), isTrue);
    expect(engine.isDue(booking, now), isTrue);
  });

  test('approved bookings expire after payDeadline', () {
    final booking = aBooking(
      status: BookingStatus.approved,
      payDeadline: now.subtract(const Duration(minutes: 1)),
    );
    expect(engine.isPaymentExpired(booking, now), isTrue);
    expect(engine.isDue(booking, now), isTrue);
  });

  test('terminal and future bookings are not due', () {
    expect(
      engine.isDue(
        aBooking(
          status: BookingStatus.cancelled,
          expiresAt: now.subtract(const Duration(days: 1)),
        ),
        now,
      ),
      isFalse,
    );
    expect(
      engine.isDue(
        aBooking(
          status: BookingStatus.approved,
          payDeadline: now.add(const Duration(hours: 1)),
        ),
        now,
      ),
      isFalse,
    );
  });
}
