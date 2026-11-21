import 'package:veloce/core/constants/app_constants.dart';
import 'package:veloce/core/domain/entities/booking.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';

/// Lazy time rules: pending requests expire after 24 h and approved bookings at
/// the earlier of 24 h after approval and the end of the pickup day
/// (TECHNICAL.md §5.4).
class ExpiryEngine {
  const ExpiryEngine({
    this.pendingWindow = AppConstants.pendingExpiry,
    this.paymentWindow = AppConstants.paymentWindow,
    this.reminderWindow = const Duration(hours: 6),
  });

  final Duration pendingWindow;
  final Duration paymentWindow;

  /// How long before the payment deadline the renter is reminded.
  final Duration reminderWindow;

  /// The pickup date is a day, not a time, so payment stays possible until the
  /// pickup day ends (a same-day pickup can still be approved and paid).
  DateTime pickupDeadline(DateTime pickupAt) =>
      DateTime(pickupAt.year, pickupAt.month, pickupAt.day + 1);

  /// Payment is due by the end of the pickup day even when that is less than
  /// 24 h away.
  DateTime paymentDeadline({
    required DateTime approvedAt,
    required DateTime pickupAt,
  }) {
    final windowEnd = approvedAt.add(paymentWindow);
    final pickupEnd = pickupDeadline(pickupAt);
    return pickupEnd.isBefore(windowEnd) ? pickupEnd : windowEnd;
  }

  /// An approved booking whose deadline is within [reminderWindow].
  bool isPaymentDeadlineNear(Booking booking, DateTime now) {
    final deadline = booking.payDeadline;
    return booking.status == BookingStatus.approved &&
        deadline != null &&
        !now.isAfter(deadline) &&
        deadline.difference(now) <= reminderWindow;
  }

  bool isPendingExpired(Booking booking, DateTime now) {
    final expiresAt = booking.expiresAt;
    return booking.status == BookingStatus.pending &&
        expiresAt != null &&
        now.isAfter(expiresAt);
  }

  bool isPaymentExpired(Booking booking, DateTime now) {
    final deadline = booking.payDeadline;
    return booking.status == BookingStatus.approved &&
        deadline != null &&
        now.isAfter(deadline);
  }

  bool isDue(Booking booking, DateTime now) =>
      isPendingExpired(booking, now) || isPaymentExpired(booking, now);
}
