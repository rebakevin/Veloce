import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/features/booking/domain/services/expiry_engine.dart';

import '../../../support/builders.dart';

void main() {
  const engine = ExpiryEngine();
  final now = DateTime(2026, 11, 10, 12);

  test('the payment deadline is the earlier of 24 h and pickup', () {
    final after24h = now.add(const Duration(hours: 24));
    expect(
      engine.paymentDeadline(
        approvedAt: now,
        pickupAt: now.add(const Duration(days: 3)),
      ),
      after24h,
    );
    final pickup = now.add(const Duration(hours: 5));
    expect(engine.paymentDeadline(approvedAt: now, pickupAt: pickup), pickup);
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
