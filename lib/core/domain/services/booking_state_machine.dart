import '../entities/booking.dart';
import '../entities/renter_lock.dart';
import '../enums/booking_actor.dart';
import '../enums/booking_status.dart';

/// The only legal booking transitions (TECHNICAL.md §5.1). The Firestore rules
/// enforce the same table; keep the two in sync.
class BookingStateMachine {
  const BookingStateMachine();

  static const Map<(BookingStatus, BookingStatus), Set<BookingActor>>
  _transitions = {
    (BookingStatus.pending, BookingStatus.approved): {BookingActor.owner},
    (BookingStatus.pending, BookingStatus.declined): {BookingActor.owner},
    (BookingStatus.pending, BookingStatus.cancelled): {BookingActor.renter},
    (BookingStatus.pending, BookingStatus.expired): _both,
    (BookingStatus.approved, BookingStatus.confirmed): {BookingActor.renter},
    (BookingStatus.approved, BookingStatus.cancelled): _both,
    (BookingStatus.approved, BookingStatus.expired): _both,
    (BookingStatus.confirmed, BookingStatus.active): _both,
    (BookingStatus.confirmed, BookingStatus.cancelled): _both,
    (BookingStatus.active, BookingStatus.returning): _both,
    (BookingStatus.returning, BookingStatus.review): {BookingActor.owner},
    (BookingStatus.returning, BookingStatus.completed): _both,
    (BookingStatus.review, BookingStatus.completed): _both,
  };

  static const Set<BookingActor> _both = {
    BookingActor.renter,
    BookingActor.owner,
  };

  bool canTransition(
    BookingStatus from,
    BookingStatus to,
    BookingActor actor,
  ) => _transitions[(from, to)]?.contains(actor) ?? false;

  /// Statuses a booking can still move out of.
  bool isTerminal(BookingStatus status) =>
      !_transitions.keys.any((transition) => transition.$1 == status);

  /// The status users should see, resolving what lazy expiry and the renter
  /// lock have not persisted yet. [renterLock] is the lock held by the renter.
  BookingStatus effectiveStatus(
    Booking booking, {
    required DateTime now,
    RenterLock? renterLock,
  }) {
    final isOpen =
        booking.status == BookingStatus.pending ||
        booking.status == BookingStatus.approved;
    if (!isOpen) return booking.status;

    final lockedElsewhere =
        renterLock != null && renterLock.bookingId != booking.id;
    if (lockedElsewhere) return BookingStatus.cancelled;

    final deadline = booking.status == BookingStatus.pending
        ? booking.expiresAt
        : booking.payDeadline;
    if (deadline != null && now.isAfter(deadline)) return BookingStatus.expired;
    return booking.status;
  }
}
