import 'package:veloce/core/domain/entities/booking.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';

/// Date-overlap rules for competing requests on one car (TECHNICAL.md §5.4).
class BookingOverlap {
  const BookingOverlap();

  bool overlaps({
    required DateTime start,
    required DateTime end,
    required DateTime otherStart,
    required DateTime otherEnd,
  }) => start.isBefore(otherEnd) && otherStart.isBefore(end);

  /// Pending requests on [target]'s car whose dates overlap it, excluding
  /// [target] itself.
  List<Booking> pendingOverlaps(Booking target, Iterable<Booking> candidates) =>
      candidates
          .where(
            (candidate) =>
                candidate.id != target.id &&
                candidate.vehicleId == target.vehicleId &&
                candidate.status == BookingStatus.pending &&
                overlaps(
                  start: target.startDate,
                  end: target.endDate,
                  otherStart: candidate.startDate,
                  otherEnd: candidate.endDate,
                ),
          )
          .toList();
}
