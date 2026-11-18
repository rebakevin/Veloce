import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:veloce/core/constants/firestore_fields.dart';
import 'package:veloce/core/constants/firestore_paths.dart';
import 'package:veloce/core/data/models/booking_contact_model.dart';
import 'package:veloce/core/data/models/booking_model.dart';
import 'package:veloce/core/data/models/calendar_block_model.dart';
import 'package:veloce/core/data/models/contact_model.dart';
import 'package:veloce/core/data/models/renter_lock_model.dart';
import 'package:veloce/core/data/services/failure_mapper.dart';
import 'package:veloce/core/data/services/user_lookup.dart';
import 'package:veloce/core/data/services/vehicle_lookup.dart';
import 'package:veloce/core/domain/entities/booking.dart';
import 'package:veloce/core/domain/entities/booking_contact.dart';
import 'package:veloce/core/domain/entities/calendar_block.dart';
import 'package:veloce/core/domain/entities/contact.dart';
import 'package:veloce/core/domain/entities/renter_lock.dart';
import 'package:veloce/core/domain/entities/user_account.dart';
import 'package:veloce/core/domain/entities/vehicle.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/domain/enums/checklist_side.dart';
import 'package:veloce/core/domain/enums/notification_type.dart';
import 'package:veloce/core/domain/enums/party.dart';
import 'package:veloce/core/domain/enums/transaction_type.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/domain/services/atomic_write.dart';
import 'package:veloce/core/domain/services/audit_logger.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/domain/services/booking_state_machine.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/domain/services/ledger_writer.dart';
import 'package:veloce/core/domain/services/momo_gateway.dart';
import 'package:veloce/core/domain/services/notification_writer.dart';
import 'package:veloce/core/domain/services/pending_review_checker.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/core/validation/validators.dart';

import '../domain/entities/booking_view.dart';
import '../domain/repositories/booking_repository.dart';
import '../domain/services/booking_overlap.dart';
import '../domain/services/cancellation_policy.dart';
import '../domain/services/expiry_engine.dart';

/// [BookingRepository] on Firestore. Reads use the cached lookups; every
/// transition is one batch so the rules can verify the whole change.
class FirestoreBookingRepository implements BookingRepository {
  const FirestoreBookingRepository({
    required this._firestore,
    required this._writes,
    required this._users,
    required this._vehicles,
    required this._ledger,
    required this._audit,
    required this._notifications,
    required this._momo,
    required this._pendingReviews,
    required this._session,
    required this._clock,
    required this._stateMachine,
    required this._overlap,
    required this._expiry,
    required this._cancellation,
  });

  static const Duration _timeout = Duration(seconds: 20);

  final FirebaseFirestore _firestore;
  final AtomicWriteFactory _writes;
  final UserLookup _users;
  final VehicleLookup _vehicles;
  final LedgerWriter _ledger;
  final AuditLogger _audit;
  final NotificationWriter _notifications;
  final MomoGateway _momo;
  final PendingReviewChecker _pendingReviews;
  final AuthSession _session;
  final Clock _clock;
  final BookingStateMachine _stateMachine;
  final BookingOverlap _overlap;
  final ExpiryEngine _expiry;
  final CancellationPolicy _cancellation;

  CollectionReference<Map<String, dynamic>> get _bookings =>
      _firestore.collection(FirestorePaths.bookings);

  @override
  Stream<Result<List<BookingView>>> watchMyBookings() {
    final userId = _session.currentUserId;
    final role = _session.role;
    if (userId == null || role == null) {
      return Stream.value(_signedOut());
    }
    final field = role == UserRole.renter
        ? FirestoreFields.renterId
        : FirestoreFields.ownerId;
    final source = _bookings
        .where(field, isEqualTo: userId)
        .orderBy(FirestoreFields.createdAt, descending: true)
        .snapshots();
    return _mapStream(
      source,
      (snapshot) => _views(snapshot.docs, applyLock: role == UserRole.renter),
    );
  }

  @override
  Stream<Result<BookingView>> watchBooking(String bookingId) {
    final role = _session.role;
    if (role == null) return Stream.value(_signedOut());
    return _mapStream(
      _bookings.doc(bookingId).snapshots(),
      (snapshot) =>
          _viewFromSnapshot(snapshot, applyLock: role == UserRole.renter),
    );
  }

  @override
  Future<Result<BookingView>> getBooking(String bookingId) async {
    final role = _session.role;
    if (role == null) return _signedOut();
    final booking = await _readBooking(bookingId);
    if (booking case Failure(:final failure)) return Result.failure(failure);
    return _viewFromBooking(
      (booking as Success<Booking>).value,
      applyLock: role == UserRole.renter,
    );
  }

  @override
  Future<Result<BookingContact?>> getCounterpartyContact(
    String bookingId,
  ) async {
    final role = _session.role;
    if (role == null) return _signedOut();
    final view = await getBooking(bookingId);
    if (view case Failure(:final failure)) return Result.failure(failure);
    final bookingView = (view as Success<BookingView>).value;
    if (!bookingView.isContactUnlocked) {
      return const Result.success(null);
    }
    final side = role == UserRole.renter
        ? ChecklistSide.owner
        : ChecklistSide.renter;
    final result = await _readBookingContact(bookingId, side);
    return result;
  }

  @override
  Future<Result<void>> approve(String bookingId) async {
    final ownerId = _session.currentUserId;
    final role = _session.role;
    if (ownerId == null || role != UserRole.owner) {
      return const Result.failure(
        PermissionFailure('Only the car owner can approve a request.'),
      );
    }

    final bookingResult = await _readBooking(bookingId);
    if (bookingResult case Failure(:final failure)) {
      return Result.failure(failure);
    }
    final booking = (bookingResult as Success<Booking>).value;
    final now = _clock.now();
    if (booking.ownerId != ownerId) {
      return const Result.failure(
        PermissionFailure('Only the car owner can approve a request.'),
      );
    }
    if (booking.status != BookingStatus.pending) {
      return const Result.failure(
        ConflictFailure('This request is no longer pending.'),
      );
    }
    if (_expiry.isPendingExpired(booking, now)) {
      return const Result.failure(ConflictFailure('This request has expired.'));
    }
    if (await _pendingReviews.hasPendingReview(ownerId)) {
      return const Result.failure(
        ConflictFailure('Write your pending review before approving.'),
      );
    }
    final lock = await _readLock(booking.renterId);
    if (lock case Failure(:final failure)) {
      return Result.failure(failure);
    }
    if ((lock as Success<RenterLock?>).value != null) {
      return const Result.failure(
        ConflictFailure('This renter is already booked.'),
      );
    }

    final vehicleResult = await _vehicles.byId(booking.vehicleId);
    if (vehicleResult case Failure(:final failure)) {
      return Result.failure(failure);
    }
    final vehicle = (vehicleResult as Success<Vehicle>).value;
    final contactResult = await _readOwnerContact(ownerId);
    if (contactResult case Failure(:final failure)) {
      return Result.failure(failure);
    }
    final ownerContact = (contactResult as Success<Contact>).value;

    final overlapsResult = await _pendingOverlaps(booking);
    if (overlapsResult case Failure(:final failure)) {
      return Result.failure(failure);
    }
    final overlaps = (overlapsResult as Success<List<Booking>>).value;
    final deadline = _expiry.paymentDeadline(
      approvedAt: now,
      pickupAt: booking.startDate,
    );

    try {
      final write = _writes.begin();
      write.update(FirestorePaths.booking(booking.id), {
        FirestoreFields.status: BookingStatus.approved.key,
        FirestoreFields.payDeadline: Timestamp.fromDate(deadline),
        FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
      });
      write.set(
        FirestorePaths.bookingPrivate(booking.id, ChecklistSide.owner.key),
        BookingContactModel.toMap(
          BookingContact(
            side: ChecklistSide.owner,
            bookingId: booking.id,
            phone: ownerContact.phone,
            email: ownerContact.email,
            meetingPoint: '${vehicle.neighbourhood} roundabout',
          ),
        ),
      );
      write.set(
        '${FirestorePaths.renterLocks}/${booking.renterId}',
        RenterLockModel.toMap(
          RenterLock(
            renterId: booking.renterId,
            bookingId: booking.id,
            createdAt: now,
          ),
        )..[FirestoreFields.createdAt] = FieldValue.serverTimestamp(),
      );
      write.set(
        '${FirestorePaths.calendarBlocks}/${booking.id}',
        CalendarBlockModel.toMap(
          CalendarBlock(
            bookingId: booking.id,
            vehicleId: booking.vehicleId,
            startDate: booking.startDate,
            endDate: booking.endDate,
          ),
        ),
      );

      for (final overlap in overlaps) {
        _declineOverlap(write, overlap, vehicle);
      }

      _audit.record(
        write,
        actorId: ownerId,
        entityType: 'booking',
        entityId: booking.id,
        oldState: BookingStatus.pending.key,
        newState: BookingStatus.approved.key,
      );
      _notifications.send(
        write,
        userId: booking.renterId,
        type: NotificationType.requestApproved,
        title: 'Request approved',
        text: 'Pay before the deadline to confirm your booking.',
        bookingId: booking.id,
      );
      await write.commit().timeout(_timeout);
      return const Result.success(null);
    } on Object catch (error, stackTrace) {
      return Result.failure(
        _transitionFailure(
          error,
          stackTrace,
          'This renter is already booked, or the request changed. Refresh and try again.',
        ),
      );
    }
  }

  @override
  Future<Result<void>> decline(
    String bookingId, {
    required String reason,
  }) async {
    final ownerId = _session.currentUserId;
    if (ownerId == null || _session.role != UserRole.owner) {
      return const Result.failure(
        PermissionFailure('Only the car owner can decline a request.'),
      );
    }
    final problem = Validators.requiredText(reason, field: 'A reason');
    if (problem != null) {
      return Result.failure(ValidationFailure(problem));
    }
    final bookingResult = await _readBooking(bookingId);
    if (bookingResult case Failure(:final failure)) {
      return Result.failure(failure);
    }
    final booking = (bookingResult as Success<Booking>).value;
    if (booking.ownerId != ownerId) {
      return const Result.failure(
        PermissionFailure('Only the car owner can decline a request.'),
      );
    }
    if (booking.status != BookingStatus.pending) {
      return const Result.failure(
        ConflictFailure('This request is no longer pending.'),
      );
    }
    if (_expiry.isPendingExpired(booking, _clock.now())) {
      return const Result.failure(ConflictFailure('This request has expired.'));
    }

    try {
      final write = _writes.begin();
      write.update(FirestorePaths.booking(booking.id), {
        FirestoreFields.status: BookingStatus.declined.key,
        FirestoreFields.reason: reason.trim(),
        FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
      });
      _audit.record(
        write,
        actorId: ownerId,
        entityType: 'booking',
        entityId: booking.id,
        oldState: BookingStatus.pending.key,
        newState: BookingStatus.declined.key,
      );
      _notifications.send(
        write,
        userId: booking.renterId,
        type: NotificationType.requestDeclined,
        title: 'Request declined',
        text: reason.trim(),
        bookingId: booking.id,
      );
      await write.commit().timeout(_timeout);
      return const Result.success(null);
    } on Object catch (error, stackTrace) {
      return Result.failure(
        _transitionFailure(
          error,
          stackTrace,
          'This request changed. Refresh and try again.',
        ),
      );
    }
  }

  @override
  Future<Result<void>> cancel(String bookingId, {String? reason}) async {
    final userId = _session.currentUserId;
    final role = _session.role;
    if (userId == null || role == null) return _signedOut();

    final bookingResult = await _readBooking(bookingId);
    if (bookingResult case Failure(:final failure)) {
      return Result.failure(failure);
    }
    final booking = (bookingResult as Success<Booking>).value;
    if (booking.renterId != userId && booking.ownerId != userId) {
      return const Result.failure(
        PermissionFailure('Only the parties can cancel this booking.'),
      );
    }
    final lockResult = await _readLock(booking.renterId);
    if (lockResult case Failure(:final failure)) {
      return Result.failure(failure);
    }
    final renterLock = (lockResult as Success<RenterLock?>).value;
    final effective = _stateMachine.effectiveStatus(
      booking,
      now: _clock.now(),
      renterLock: role == UserRole.renter ? renterLock : null,
    );
    if (!_cancellation.canCancel(effective)) {
      return const Result.failure(
        ConflictFailure('This booking can no longer be cancelled.'),
      );
    }
    final refund = _cancellation.refundableAmount(booking);
    final byOwner = role == UserRole.owner;
    final storedReason = reason?.trim().isNotEmpty == true
        ? reason!.trim()
        : byOwner
        ? 'The owner cancelled this booking before pickup.'
        : 'Cancelled before pickup was confirmed.';

    try {
      final write = _writes.begin();
      write.update(FirestorePaths.booking(booking.id), {
        FirestoreFields.status: BookingStatus.cancelled.key,
        FirestoreFields.reason: storedReason,
        FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
      });
      write.delete('${FirestorePaths.calendarBlocks}/${booking.id}');
      if (renterLock?.bookingId == booking.id) {
        write.delete('${FirestorePaths.renterLocks}/${booking.renterId}');
      }
      if (refund > 0) {
        _ledger.record(
          write,
          booking: booking,
          type: TransactionType.refund,
          amount: refund,
          from: Party.veloce,
          to: Party.renter,
          reference: 'REFUND-${booking.reference}',
        );
      }
      _audit.record(
        write,
        actorId: userId,
        entityType: 'booking',
        entityId: booking.id,
        oldState: booking.status.key,
        newState: BookingStatus.cancelled.key,
      );
      final otherId = byOwner ? booking.renterId : booking.ownerId;
      _notifications.send(
        write,
        userId: otherId,
        type: NotificationType.bookingCancelled,
        title: 'Booking cancelled',
        text: refund > 0
            ? 'The booking was cancelled and everything paid was refunded.'
            : 'The booking was cancelled before pickup.',
        bookingId: booking.id,
      );
      await write.commit().timeout(_timeout);
      return const Result.success(null);
    } on Object catch (error, stackTrace) {
      return Result.failure(
        _transitionFailure(
          error,
          stackTrace,
          'This booking changed. Refresh and try again.',
        ),
      );
    }
  }

  @override
  Future<Result<MomoReceipt>> pay(
    String bookingId, {
    required String momoNumber,
  }) async {
    final renterId = _session.currentUserId;
    if (renterId == null || _session.role != UserRole.renter) {
      return const Result.failure(
        PermissionFailure('Only the renter can pay for this booking.'),
      );
    }
    final problem = Validators.momoNumber(momoNumber);
    if (problem != null) {
      return Result.failure(ValidationFailure(problem));
    }
    final bookingResult = await _readBooking(bookingId);
    if (bookingResult case Failure(:final failure)) {
      return Result.failure(failure);
    }
    final booking = (bookingResult as Success<Booking>).value;
    if (booking.renterId != renterId) {
      return const Result.failure(
        PermissionFailure('Only the renter can pay for this booking.'),
      );
    }
    if (booking.status != BookingStatus.approved) {
      return const Result.failure(
        ConflictFailure('This booking is not waiting for payment.'),
      );
    }
    if (_expiry.isPaymentExpired(booking, _clock.now())) {
      return const Result.failure(
        ConflictFailure('The payment deadline has passed.'),
      );
    }

    final charged = await _momo.charge(
      momoNumber: momoNumber.trim(),
      amount: booking.totalPayable,
      bookingReference: booking.reference,
    );
    if (charged case Failure<MomoReceipt>(:final failure)) {
      return Result.failure(failure);
    }
    final receipt = (charged as Success<MomoReceipt>).value;

    try {
      final write = _writes.begin();
      write.update(FirestorePaths.booking(booking.id), {
        FirestoreFields.status: BookingStatus.confirmed.key,
        FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
      });
      _ledger.record(
        write,
        booking: booking,
        type: TransactionType.charge,
        amount: booking.totalPayable,
        from: Party.renter,
        to: Party.veloce,
        reference: receipt.reference,
      );
      _audit.record(
        write,
        actorId: renterId,
        entityType: 'booking',
        entityId: booking.id,
        oldState: BookingStatus.approved.key,
        newState: BookingStatus.confirmed.key,
      );
      _notifications.send(
        write,
        userId: booking.ownerId,
        type: NotificationType.paymentReceived,
        title: 'Payment received',
        text: 'The renter paid for ${booking.reference}.',
        bookingId: booking.id,
      );
      await write.commit().timeout(_timeout);
      return Result.success(receipt);
    } on Object catch (error, stackTrace) {
      return Result.failure(
        _transitionFailure(
          error,
          stackTrace,
          'The booking changed before the payment was recorded. Refresh and try again.',
        ),
      );
    }
  }

  @override
  Future<Result<void>> acknowledgeAgreement(String bookingId) async {
    final renterId = _session.currentUserId;
    if (renterId == null || _session.role != UserRole.renter) {
      return const Result.failure(
        PermissionFailure('Only the renter can accept the agreement.'),
      );
    }
    final bookingResult = await _readBooking(bookingId);
    if (bookingResult case Failure(:final failure)) {
      return Result.failure(failure);
    }
    final booking = (bookingResult as Success<Booking>).value;
    if (booking.renterId != renterId) {
      return const Result.failure(
        PermissionFailure('Only the renter can accept the agreement.'),
      );
    }
    if (booking.agreementAckAt != null) {
      return const Result.success(null);
    }
    final now = _clock.now();
    if (booking.status != BookingStatus.approved &&
        booking.status != BookingStatus.confirmed) {
      return const Result.failure(
        ConflictFailure('The agreement opens after approval.'),
      );
    }
    if (_expiry.isPaymentExpired(booking, now)) {
      return const Result.failure(
        ConflictFailure('The payment deadline has passed.'),
      );
    }

    try {
      final write = _writes.begin();
      write.update(FirestorePaths.booking(booking.id), {
        FirestoreFields.agreementAckAt: FieldValue.serverTimestamp(),
        FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
      });
      _audit.record(
        write,
        actorId: renterId,
        entityType: 'booking',
        entityId: booking.id,
        oldState: booking.status.key,
        newState: booking.status.key,
      );
      await write.commit().timeout(_timeout);
      return const Result.success(null);
    } on Object catch (error, stackTrace) {
      return Result.failure(
        _transitionFailure(
          error,
          stackTrace,
          'This booking changed. Refresh and try again.',
        ),
      );
    }
  }

  @override
  Future<Result<int>> expireDueBookings() async {
    final userId = _session.currentUserId;
    final role = _session.role;
    if (userId == null || role == null) return _signedOut();
    final field = role == UserRole.renter
        ? FirestoreFields.renterId
        : FirestoreFields.ownerId;

    try {
      final snapshot = await _bookings
          .where(field, isEqualTo: userId)
          .get()
          .timeout(_timeout);
      final lockResult = role == UserRole.renter
          ? await _readLock(userId)
          : const Result<RenterLock?>.success(null);
      if (lockResult case Failure(:final failure)) {
        return Result.failure(failure);
      }
      final renterLock = (lockResult as Success<RenterLock?>).value;
      var written = 0;
      for (final doc in snapshot.docs) {
        final booking = _parse(() => BookingModel.fromMap(doc.id, doc.data()));
        if (booking case Failure<Booking>(:final failure)) {
          return Result.failure(failure);
        }
        final value = (booking as Success<Booking>).value;
        final effective = _stateMachine.effectiveStatus(
          value,
          now: _clock.now(),
          renterLock: role == UserRole.renter ? renterLock : null,
        );
        if (effective != BookingStatus.expired) continue;
        final expired = await _expire(value, renterLock);
        if (expired case Failure<void>(:final failure)) {
          return Result.failure(failure);
        }
        written++;
      }
      return Result.success(written);
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }

  Future<Result<void>> _expire(Booking booking, RenterLock? renterLock) async {
    final reason = booking.status == BookingStatus.pending
        ? 'The owner did not respond in time.'
        : 'Payment was not made in time.';
    var lock = renterLock;
    if (lock == null && booking.status == BookingStatus.approved) {
      final loaded = await _readLock(booking.renterId);
      if (loaded case Failure<RenterLock?>(:final failure)) {
        return Result.failure(failure);
      }
      lock = (loaded as Success<RenterLock?>).value;
    }
    try {
      final write = _writes.begin();
      write.update(FirestorePaths.booking(booking.id), {
        FirestoreFields.status: BookingStatus.expired.key,
        FirestoreFields.reason: reason,
        FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
      });
      write.delete('${FirestorePaths.calendarBlocks}/${booking.id}');
      if (lock?.bookingId == booking.id) {
        write.delete('${FirestorePaths.renterLocks}/${booking.renterId}');
      }
      _audit.record(
        write,
        actorId: _session.currentUserId!,
        entityType: 'booking',
        entityId: booking.id,
        oldState: booking.status.key,
        newState: BookingStatus.expired.key,
      );
      for (final userId in {booking.renterId, booking.ownerId}) {
        _notifications.send(
          write,
          userId: userId,
          type: NotificationType.requestExpired,
          title: 'Booking expired',
          text: reason,
          bookingId: booking.id,
        );
      }
      await write.commit().timeout(_timeout);
      return const Result.success(null);
    } on Object catch (error, stackTrace) {
      return Result.failure(
        _transitionFailure(
          error,
          stackTrace,
          'This booking changed while it was expiring. Refresh and try again.',
        ),
      );
    }
  }

  void _declineOverlap(AtomicWrite write, Booking overlap, Vehicle vehicle) {
    write.update(FirestorePaths.booking(overlap.id), {
      FirestoreFields.status: BookingStatus.declined.key,
      FirestoreFields.reason: 'The car has been booked for these dates.',
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
    });
    _audit.record(
      write,
      actorId: _session.currentUserId!,
      entityType: 'booking',
      entityId: overlap.id,
      oldState: BookingStatus.pending.key,
      newState: BookingStatus.declined.key,
    );
    _notifications.send(
      write,
      userId: overlap.renterId,
      type: NotificationType.requestDeclined,
      title: 'Request declined',
      text:
          'The ${vehicle.make} ${vehicle.model} has been booked for those dates.',
      bookingId: overlap.id,
    );
  }

  Future<Result<List<Booking>>> _pendingOverlaps(Booking booking) async {
    try {
      final snapshot = await _bookings
          .where(FirestoreFields.vehicleId, isEqualTo: booking.vehicleId)
          .where(FirestoreFields.status, isEqualTo: BookingStatus.pending.key)
          .where(
            FirestoreFields.startDate,
            isLessThan: Timestamp.fromDate(booking.endDate),
          )
          .orderBy(FirestoreFields.startDate)
          .get()
          .timeout(_timeout);
      final candidates = <Booking>[];
      for (final doc in snapshot.docs) {
        final parsed = _parse(() => BookingModel.fromMap(doc.id, doc.data()));
        if (parsed case Failure<Booking>(:final failure)) {
          return Result.failure(failure);
        }
        candidates.add((parsed as Success<Booking>).value);
      }
      return Result.success(_overlap.pendingOverlaps(booking, candidates));
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }

  Future<Result<List<BookingView>>> _views(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
    required bool applyLock,
  }) async {
    try {
      final userId = _session.currentUserId;
      final lockResult = applyLock && userId != null
          ? await _readLock(userId)
          : const Result<RenterLock?>.success(null);
      if (lockResult case Failure(:final failure)) {
        return Result.failure(failure);
      }
      final lock = (lockResult as Success<RenterLock?>).value;
      final views = <BookingView>[];
      for (final doc in docs) {
        final parsed = _parse(() => BookingModel.fromMap(doc.id, doc.data()));
        if (parsed case Failure<Booking>(:final failure)) {
          return Result.failure(failure);
        }
        final view = await _viewFromBooking(
          (parsed as Success<Booking>).value,
          applyLock: applyLock,
          lock: lock,
        );
        if (view case Failure<BookingView>(:final failure)) {
          return Result.failure(failure);
        }
        views.add((view as Success<BookingView>).value);
      }
      return Result.success(views);
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }

  Future<Result<BookingView>> _viewFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot, {
    required bool applyLock,
  }) {
    final data = snapshot.data();
    if (data == null) {
      return Future.value(const Result.failure(NotFoundFailure()));
    }
    final parsed = _parse(() => BookingModel.fromMap(snapshot.id, data));
    if (parsed case Failure<Booking>(:final failure)) {
      return Future.value(Result.failure(failure));
    }
    return _viewFromBooking(
      (parsed as Success<Booking>).value,
      applyLock: applyLock,
    );
  }

  Future<Result<BookingView>> _viewFromBooking(
    Booking booking, {
    required bool applyLock,
    RenterLock? lock,
  }) async {
    final vehicle = await _vehicles.byId(booking.vehicleId);
    if (vehicle case Failure<Vehicle>(:final failure)) {
      return Result.failure(failure);
    }
    final renter = await _users.byId(booking.renterId);
    if (renter case Failure<UserAccount>(:final failure)) {
      return Result.failure(failure);
    }
    final owner = await _users.byId(booking.ownerId);
    if (owner case Failure<UserAccount>(:final failure)) {
      return Result.failure(failure);
    }
    RenterLock? renterLock;
    if (applyLock) {
      if (lock != null) {
        renterLock = lock;
      } else {
        final lockResult = await _readLock(booking.renterId);
        if (lockResult case Failure<RenterLock?>(:final failure)) {
          return Result.failure(failure);
        }
        renterLock = (lockResult as Success<RenterLock?>).value;
      }
    }
    return Result.success(
      BookingView(
        booking: booking,
        effectiveStatus: _stateMachine.effectiveStatus(
          booking,
          now: _clock.now(),
          renterLock: renterLock,
        ),
        vehicle: (vehicle as Success<Vehicle>).value,
        renter: (renter as Success<UserAccount>).value,
        owner: (owner as Success<UserAccount>).value,
      ),
    );
  }

  Future<Result<Booking>> _readBooking(String bookingId) async {
    try {
      final snapshot = await _bookings.doc(bookingId).get().timeout(_timeout);
      final data = snapshot.data();
      if (data == null) return const Result.failure(NotFoundFailure());
      return _parse(() => BookingModel.fromMap(snapshot.id, data));
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }

  Future<Result<RenterLock?>> _readLock(String renterId) async {
    try {
      final snapshot = await _firestore
          .doc('${FirestorePaths.renterLocks}/$renterId')
          .get()
          .timeout(_timeout);
      final data = snapshot.data();
      if (data == null) return const Result.success(null);
      return _parse(() => RenterLockModel.fromMap(snapshot.id, data));
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }

  Future<Result<Contact>> _readOwnerContact(String ownerId) async {
    try {
      final snapshot = await _firestore
          .doc(FirestorePaths.userPrivate(ownerId, FirestorePaths.contactDoc))
          .get()
          .timeout(_timeout);
      final data = snapshot.data();
      if (data == null) {
        return const Result.failure(
          NotFoundFailure('Add your contact details before approving.'),
        );
      }
      return _parse(() => ContactModel.fromMap(ownerId, data));
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }

  Future<Result<BookingContact?>> _readBookingContact(
    String bookingId,
    ChecklistSide side,
  ) async {
    try {
      final snapshot = await _firestore
          .doc(FirestorePaths.bookingPrivate(bookingId, side.key))
          .get()
          .timeout(_timeout);
      final data = snapshot.data();
      if (data == null) {
        return const Result.success(null);
      }
      return _parse(() => BookingContactModel.fromMap(side.key, data));
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }

  Result<T> _parse<T>(T Function() build) {
    try {
      return Result.success(build());
    } on FormatException catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }

  AppFailure _transitionFailure(
    Object error,
    StackTrace stackTrace,
    String conflictMessage,
  ) {
    if (error is FirebaseException && error.code == 'permission-denied') {
      return ConflictFailure(conflictMessage);
    }
    return mapToFailure(error, stackTrace);
  }

  Stream<Result<T>> _mapStream<S, T>(
    Stream<S> source,
    Future<Result<T>> Function(S) map,
  ) {
    late final StreamController<Result<T>> controller;
    StreamSubscription<S>? subscription;
    controller = StreamController<Result<T>>(
      onListen: () {
        subscription = source.listen(
          (event) async {
            final result = await map(event);
            if (!controller.isClosed) controller.add(result);
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!controller.isClosed) {
              controller.add(Result.failure(mapToFailure(error, stackTrace)));
            }
          },
          onDone: () {
            if (!controller.isClosed) controller.close();
          },
        );
      },
      onCancel: () async {
        await subscription?.cancel();
      },
    );
    return controller.stream;
  }

  Result<T> _signedOut<T>() =>
      const Result.failure(PermissionFailure('Sign in to see your bookings.'));
}
