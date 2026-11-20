import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/domain/enums/subject_type.dart';

/// The id and status of a booking the user took part in.
class BookingRef {
  const BookingRef({required this.id, required this.status});

  final String id;
  final BookingStatus status;
}

/// Decides which reviews a user still owes for completed bookings.
///
/// - As a renter: owes the owner review (`user`) and the car review
///   (`vehicle`).
/// - As an owner: owes the renter review (`user`).
///
/// Only completed bookings count. A review id is
/// `${bookingId}_${authorId}_${subjectType.key}`.
class PendingReviewRule {
  const PendingReviewRule();

  /// Review ids [userId] owes, renter bookings first, in booking order.
  List<String> requiredReviewIds({
    required String userId,
    required Iterable<BookingRef> renterBookings,
    required Iterable<BookingRef> ownerBookings,
  }) {
    return [
      for (final booking in _completed(renterBookings)) ...[
        _reviewId(booking.id, userId, SubjectType.user),
        _reviewId(booking.id, userId, SubjectType.vehicle),
      ],
      for (final booking in _completed(ownerBookings))
        _reviewId(booking.id, userId, SubjectType.user),
    ];
  }

  /// True when at least one required review is not in [existingReviewIds].
  bool hasMissingReview({
    required String userId,
    required Iterable<BookingRef> renterBookings,
    required Iterable<BookingRef> ownerBookings,
    required Set<String> existingReviewIds,
  }) {
    return requiredReviewIds(
      userId: userId,
      renterBookings: renterBookings,
      ownerBookings: ownerBookings,
    ).any((id) => !existingReviewIds.contains(id));
  }

  Iterable<BookingRef> _completed(Iterable<BookingRef> bookings) =>
      bookings.where((b) => b.status == BookingStatus.completed);

  String _reviewId(String bookingId, String authorId, SubjectType subject) =>
      '${bookingId}_${authorId}_${subject.key}';
}
