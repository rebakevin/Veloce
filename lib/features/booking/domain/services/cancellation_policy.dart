import 'package:veloce/core/domain/entities/booking.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';

/// Cancellation is free until both sides confirm pickup. A paid booking gets
/// the rental fee and caution fee back; an unpaid one has nothing to refund.
class CancellationPolicy {
  const CancellationPolicy();

  bool canCancel(BookingStatus status) => switch (status) {
    BookingStatus.pending ||
    BookingStatus.approved ||
    BookingStatus.confirmed => true,
    _ => false,
  };

  int refundableAmount(Booking booking) =>
      booking.status == BookingStatus.confirmed ? booking.totalPayable : 0;
}
