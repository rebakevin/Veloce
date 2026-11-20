import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/features/booking/domain/services/cancellation_policy.dart';

import '../../../support/builders.dart';

void main() {
  const policy = CancellationPolicy();

  test('cancellation is open until pickup is confirmed', () {
    for (final status in [
      BookingStatus.pending,
      BookingStatus.approved,
      BookingStatus.confirmed,
    ]) {
      expect(policy.canCancel(status), isTrue, reason: status.key);
    }
    for (final status in [
      BookingStatus.active,
      BookingStatus.returning,
      BookingStatus.review,
      BookingStatus.completed,
      BookingStatus.cancelled,
      BookingStatus.expired,
      BookingStatus.declined,
    ]) {
      expect(policy.canCancel(status), isFalse, reason: status.key);
    }
  });

  test('only a paid booking refunds the full total', () {
    final confirmed = aBooking(status: BookingStatus.confirmed);
    expect(policy.refundableAmount(confirmed), confirmed.totalPayable);
    expect(
      policy.refundableAmount(aBooking(status: BookingStatus.approved)),
      0,
    );
    expect(policy.refundableAmount(aBooking()), 0);
  });
}
