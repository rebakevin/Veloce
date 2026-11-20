import 'package:veloce/core/constants/app_constants.dart';
import 'package:veloce/core/domain/entities/booking.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';

/// Lazy time rules: pending requests expire after 24 h and approved bookings at
/// the earlier of 24 h after approval and the pickup date (TECHNICAL.md §5.4).
class ExpiryEngine {
  const ExpiryEngine({
    this.pendingWindow = AppConstants.pendingExpiry,
    this.paymentWindow = AppConstants.paymentWindow,
  });

  final Duration pendingWindow;
  final Duration paymentWindow;

  /// Payment is due before the pickup even when that is less than 24 h away.
  DateTime paymentDeadline({
    required DateTime approvedAt,
    required DateTime pickupAt,
  }) {
    final windowEnd = approvedAt.add(paymentWindow);
    return pickupAt.isBefore(windowEnd) ? pickupAt : windowEnd;
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
