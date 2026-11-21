import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veloce/core/constants/firestore_fields.dart';
import 'package:veloce/core/constants/firestore_paths.dart';
import 'package:veloce/core/data/models/booking_model.dart';
import 'package:veloce/core/data/models/caution_claim_model.dart';
import 'package:veloce/core/data/models/checklist_entry_model.dart';
import 'package:veloce/core/data/models/checklist_media_model.dart';
import 'package:veloce/core/data/services/failure_mapper.dart';
import 'package:veloce/core/data/services/firestore_transaction_write.dart';
import 'package:veloce/core/domain/entities/booking.dart';
import 'package:veloce/core/domain/entities/caution_claim.dart';
import 'package:veloce/core/domain/entities/checklist_entry.dart';
import 'package:veloce/core/domain/entities/checklist_media.dart';
import 'package:veloce/core/domain/entities/claim_history_entry.dart';
import 'package:veloce/core/domain/enums/booking_actor.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/domain/enums/caution_decision.dart';
import 'package:veloce/core/domain/enums/checklist_kind.dart';
import 'package:veloce/core/domain/enums/checklist_side.dart';
import 'package:veloce/core/domain/enums/claim_response.dart';
import 'package:veloce/core/domain/enums/claim_status.dart';
import 'package:veloce/core/domain/enums/notification_type.dart';
import 'package:veloce/core/domain/enums/party.dart';
import 'package:veloce/core/domain/enums/transaction_type.dart';
import 'package:veloce/core/domain/services/atomic_write.dart';
import 'package:veloce/core/domain/services/audit_logger.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/domain/services/booking_state_machine.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/domain/services/ledger_writer.dart';
import 'package:veloce/core/domain/services/notification_writer.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';

import '../domain/repositories/handover_repository.dart';
import '../domain/services/caution_settlement_calculator.dart';
import '../domain/services/claim_amount_policy.dart';
import '../domain/services/late_fee_calculator.dart';
import '../domain/services/pickup_release_calculator.dart';
import 'completion_writer.dart';

/// Saves handover checklists and manages pickup, return and caution claims.
class FirestoreHandoverRepository implements HandoverRepository {
  const FirestoreHandoverRepository({
    required this._firestore,
    required this._writes,
    required this._session,
    required this._clock,
    required this._stateMachine,
    required this._ledger,
    required this._audit,
    required this._notifications,
  });

  static const Duration _timeout = Duration(seconds: 20);

  final FirebaseFirestore _firestore;
  final AtomicWriteFactory _writes;
  final AuthSession _session;
  final Clock _clock;
  final BookingStateMachine _stateMachine;
  final LedgerWriter _ledger;
  final AuditLogger _audit;
  final NotificationWriter _notifications;

  CompletionWriter get _completion =>
      CompletionWriter(ledger: _ledger, notifications: _notifications);

  String _claimPath(String bookingId) =>
      '${FirestorePaths.cautionClaims}/$bookingId';

  bool _isBookingParty(Booking booking, String userId, BookingActor actor) {
    return (actor == BookingActor.renter && booking.renterId == userId) ||
        (actor == BookingActor.owner && booking.ownerId == userId);
  }

  @override
  Stream<CautionClaim?> watchClaim(String bookingId) => _firestore
      .doc('${FirestorePaths.cautionClaims}/$bookingId')
      .snapshots()
      .map(
        (doc) =>
            doc.exists ? CautionClaimModel.fromMap(doc.id, doc.data()!) : null,
      );

  @override
  Future<Result<void>> saveChecklist({
    required String bookingId,
    required ChecklistKind kind,
    required ChecklistSide side,
    required List<ChecklistEntry> entries,
    required List<ChecklistMedia> media,
  }) async {
    final uid = _session.currentUserId;

    if (uid == null) {
      return const Result.failure(
        PermissionFailure('Sign in to save the checklist.'),
      );
    }

    if (bookingId.trim().isEmpty) {
      return const Result.failure(ValidationFailure('Booking ID is required.'));
    }

    for (final entry in entries) {
      if (entry.bookingId != bookingId ||
          entry.kind != kind ||
          entry.side != side) {
        return const Result.failure(
          ValidationFailure('Checklist entry does not match the booking.'),
        );
      }
    }

    for (final item in media) {
      if (item.bookingId != bookingId ||
          item.kind != kind ||
          item.side != side) {
        return const Result.failure(
          ValidationFailure('Checklist media does not match the booking.'),
        );
      }
    }

    try {
      final write = _writes.begin();
      final bookingPath = FirestorePaths.booking(bookingId);

      for (final entry in entries) {
        final path =
            '$bookingPath/${FirestorePaths.checklistEntries}/${entry.id}';

        write.set(path, {
          FirestoreFields.id: entry.id,
          FirestoreFields.bookingId: entry.bookingId,
          FirestoreFields.kind: entry.kind.key,
          FirestoreFields.side: entry.side.key,
          FirestoreFields.item: entry.item,
          FirestoreFields.ticked: entry.ticked,
          FirestoreFields.at: Timestamp.fromDate(entry.at),
        });
      }

      for (final item in media) {
        final path = '$bookingPath/${FirestorePaths.checklistMedia}/${item.id}';

        write.set(path, {
          FirestoreFields.id: item.id,
          FirestoreFields.bookingId: item.bookingId,
          FirestoreFields.kind: item.kind.key,
          FirestoreFields.side: item.side.key,
          FirestoreFields.mediaType: item.mediaType.key,
          FirestoreFields.url: item.url,
          FirestoreFields.at: Timestamp.fromDate(item.at),
        });
      }

      await write.commit().timeout(_timeout);

      return const Result.success(null);
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }

  @override
  Future<Result<SavedChecklist>> loadChecklist({
    required String bookingId,
    required ChecklistKind kind,
    required ChecklistSide side,
  }) async {
    if (_session.currentUserId == null) {
      return const Result.failure(
        PermissionFailure('Sign in to load the checklist.'),
      );
    }

    try {
      final bookingPath = FirestorePaths.booking(bookingId);

      Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> docs(
        String collection,
      ) async {
        final snapshot = await _firestore
            .collection('$bookingPath/$collection')
            .where(FirestoreFields.kind, isEqualTo: kind.key)
            .where(FirestoreFields.side, isEqualTo: side.key)
            .get()
            .timeout(_timeout);
        return snapshot.docs;
      }

      final (entries, media) = await (
        docs(FirestorePaths.checklistEntries),
        docs(FirestorePaths.checklistMedia),
      ).wait;

      return Result.success(
        SavedChecklist(
          entries: [
            for (final doc in entries)
              ChecklistEntryModel.fromMap(doc.id, doc.data()),
          ],
          media: [
            for (final doc in media)
              ChecklistMediaModel.fromMap(doc.id, doc.data()),
          ],
        ),
      );
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }

  @override
  Future<Result<Booking>> confirmPickup({
    required String bookingId,
    required String userId,
    required BookingActor actor,
  }) async {
    if (_session.currentUserId != userId) {
      return const Result.failure(
        PermissionFailure('You must be signed in to confirm pickup.'),
      );
    }

    if (bookingId.trim().isEmpty) {
      return const Result.failure(ValidationFailure('Booking ID is required.'));
    }

    try {
      final bookingRef = _firestore.doc(FirestorePaths.booking(bookingId));

      return await _firestore
          .runTransaction<Result<Booking>>((transaction) async {
            final snapshot = await transaction.get(bookingRef);

            if (!snapshot.exists || snapshot.data() == null) {
              return const Result<Booking>.failure(
                NotFoundFailure('Booking not found.'),
              );
            }

            final booking = BookingModel.fromMap(snapshot.id, snapshot.data()!);

            if (!_isBookingParty(booking, userId, actor)) {
              return const Result<Booking>.failure(
                PermissionFailure(
                  'You cannot confirm pickup for this booking.',
                ),
              );
            }

            if (booking.status != BookingStatus.confirmed) {
              return const Result<Booking>.failure(
                ValidationFailure('This booking is not ready for pickup.'),
              );
            }

            final alreadyConfirmed = actor == BookingActor.renter
                ? booking.renterPickupConfirmedAt != null
                : booking.ownerPickupConfirmedAt != null;

            if (alreadyConfirmed) {
              return const Result<Booking>.failure(
                ValidationFailure('You have already confirmed pickup.'),
              );
            }

            final now = _clock.now();

            final renterConfirmed =
                actor == BookingActor.renter ||
                booking.renterPickupConfirmedAt != null;

            final ownerConfirmed =
                actor == BookingActor.owner ||
                booking.ownerPickupConfirmedAt != null;

            final bothConfirmed = renterConfirmed && ownerConfirmed;

            if (bothConfirmed &&
                !_stateMachine.canTransition(
                  booking.status,
                  BookingStatus.active,
                  actor,
                )) {
              return const Result<Booking>.failure(
                ValidationFailure('This booking cannot move to active status.'),
              );
            }

            final updates = <String, dynamic>{
              FirestoreFields.updatedAt: Timestamp.fromDate(now),
            };

            if (actor == BookingActor.renter) {
              updates[FirestoreFields.renterPickupConfirmedAt] =
                  Timestamp.fromDate(now);
            } else {
              updates[FirestoreFields.ownerPickupConfirmedAt] =
                  Timestamp.fromDate(now);
            }

            final updatedBooking = booking.copyWith(
              renterPickupConfirmedAt: actor == BookingActor.renter
                  ? now
                  : booking.renterPickupConfirmedAt,
              ownerPickupConfirmedAt: actor == BookingActor.owner
                  ? now
                  : booking.ownerPickupConfirmedAt,
              status: bothConfirmed ? BookingStatus.active : booking.status,
              updatedAt: now,
            );

            final write = FirestoreTransactionWrite(_firestore, transaction);

            if (bothConfirmed) {
              updates[FirestoreFields.status] = BookingStatus.active.key;

              final releaseResult = PickupReleaseCalculator.calculate(
                rentalFee: booking.rentalFee,
              );

              if (releaseResult case Failure<PickupRelease>(:final failure)) {
                return Result<Booking>.failure(failure);
              }

              final pickupRelease =
                  (releaseResult as Success<PickupRelease>).value;

              _ledger.record(
                write,
                booking: updatedBooking,
                type: TransactionType.release,
                amount: pickupRelease.release,
                from: Party.veloce,
                to: Party.owner,
                reference: booking.id,
              );

              _ledger.record(
                write,
                booking: updatedBooking,
                type: TransactionType.platformFee,
                amount: pickupRelease.platformFee,
                from: Party.owner,
                to: Party.veloce,
                reference: booking.id,
              );

              if (pickupRelease.hasPayout) {
                _ledger.record(
                  write,
                  booking: updatedBooking,
                  type: TransactionType.payout,
                  amount: pickupRelease.payout,
                  from: Party.veloce,
                  to: Party.owner,
                  reference: booking.id,
                );
              }

              _notifications.send(
                write,
                userId: booking.renterId,
                type: NotificationType.pickupConfirmed,
                title: 'Pickup confirmed',
                text:
                    'Both parties confirmed pickup. Your rental is now active.',
                bookingId: booking.id,
              );

              _notifications.send(
                write,
                userId: booking.ownerId,
                type: NotificationType.pickupConfirmed,
                title: 'Pickup confirmed',
                text:
                    'Both parties confirmed pickup. The rental is now active.',
                bookingId: booking.id,
              );

              _audit.record(
                write,
                actorId: userId,
                entityType: 'booking',
                entityId: booking.id,
                oldState: booking.status.key,
                newState: BookingStatus.active.key,
              );
            } else {
              _notifications.send(
                write,
                userId: actor == BookingActor.renter
                    ? booking.ownerId
                    : booking.renterId,
                type: NotificationType.pickupConfirmed,
                title: 'Pickup confirmation waiting',
                text: 'The other party confirmed pickup. Confirm yours to start the rental.',
                bookingId: booking.id,
              );

              _audit.record(
                write,
                actorId: userId,
                entityType: 'booking',
                entityId: booking.id,
                oldState: booking.status.key,
                newState: booking.status.key,
              );
            }

            transaction.update(bookingRef, updates);

            return Result.success(updatedBooking);
          })
          .timeout(_timeout);
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }

  @override
  Future<Result<Booking>> startReturn({
    required String bookingId,
    required String userId,
    required BookingActor actor,
  }) async {
    if (_session.currentUserId != userId) {
      return const Result.failure(
        PermissionFailure('You must be signed in to start a return.'),
      );
    }

    if (bookingId.trim().isEmpty) {
      return const Result.failure(ValidationFailure('Booking ID is required.'));
    }

    try {
      final bookingRef = _firestore.doc(FirestorePaths.booking(bookingId));

      return await _firestore
          .runTransaction<Result<Booking>>((transaction) async {
            final snapshot = await transaction.get(bookingRef);

            if (!snapshot.exists || snapshot.data() == null) {
              return const Result<Booking>.failure(
                NotFoundFailure('Booking not found.'),
              );
            }

            final booking = BookingModel.fromMap(snapshot.id, snapshot.data()!);

            if (!_isBookingParty(booking, userId, actor)) {
              return const Result<Booking>.failure(
                PermissionFailure(
                  'You cannot start the return for this booking.',
                ),
              );
            }

            if (booking.status != BookingStatus.active) {
              return const Result<Booking>.failure(
                ValidationFailure('Only active bookings can start a return.'),
              );
            }

            if (!_stateMachine.canTransition(
              booking.status,
              BookingStatus.returning,
              actor,
            )) {
              return const Result<Booking>.failure(
                ValidationFailure('This booking cannot move to return status.'),
              );
            }

            final lockRef = _firestore.doc(
              '${FirestorePaths.renterLocks}/${booking.renterId}',
            );

            final lockSnapshot = await transaction.get(lockRef);

            if (lockSnapshot.exists) {
              final lockData = lockSnapshot.data();

              if (lockData == null ||
                  lockData[FirestoreFields.bookingId] != booking.id) {
                return const Result<Booking>.failure(
                  ValidationFailure(
                    'The renter lock belongs to another booking.',
                  ),
                );
              }
            }

            final now = _clock.now();

            // The renter may book again once the rental enters its return.
            if (lockSnapshot.exists) {
              transaction.delete(lockRef);
            }

            final updatedBooking = booking.copyWith(
              status: BookingStatus.returning,
              returnedAt: now,
              updatedAt: now,
            );

            final write = FirestoreTransactionWrite(_firestore, transaction);

            transaction.update(bookingRef, {
              FirestoreFields.status: BookingStatus.returning.key,
              FirestoreFields.returnedAt: Timestamp.fromDate(now),
              FirestoreFields.updatedAt: Timestamp.fromDate(now),
            });

            final otherPartyId = actor == BookingActor.renter
                ? booking.ownerId
                : booking.renterId;

            _notifications.send(
              write,
              userId: otherPartyId,
              type: NotificationType.returnConfirmed,
              title: 'Vehicle return started',
              text: 'The other party has started the vehicle return process.',
              bookingId: booking.id,
            );

            _audit.record(
              write,
              actorId: userId,
              entityType: 'booking',
              entityId: booking.id,
              oldState: booking.status.key,
              newState: BookingStatus.returning.key,
            );

            return Result.success(updatedBooking);
          })
          .timeout(_timeout);
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }

  @override
  Future<Result<Booking>> confirmReturn({
    required String bookingId,
    required String userId,
    required BookingActor actor,
  }) async {
    if (_session.currentUserId != userId) {
      return const Result.failure(
        PermissionFailure('You must be signed in to confirm the return.'),
      );
    }

    if (bookingId.trim().isEmpty) {
      return const Result.failure(ValidationFailure('Booking ID is required.'));
    }

    try {
      final bookingRef = _firestore.doc(FirestorePaths.booking(bookingId));

      return await _firestore
          .runTransaction<Result<Booking>>((transaction) async {
            final snapshot = await transaction.get(bookingRef);

            if (!snapshot.exists || snapshot.data() == null) {
              return const Result<Booking>.failure(
                NotFoundFailure('Booking not found.'),
              );
            }

            final booking = BookingModel.fromMap(snapshot.id, snapshot.data()!);

            if (!_isBookingParty(booking, userId, actor)) {
              return const Result<Booking>.failure(
                PermissionFailure(
                  'You cannot confirm the return for this booking.',
                ),
              );
            }

            if (booking.status != BookingStatus.returning) {
              return const Result<Booking>.failure(
                ValidationFailure('This booking is not in return status.'),
              );
            }

            final alreadyConfirmed = actor == BookingActor.renter
                ? booking.renterReturnConfirmedAt != null
                : booking.ownerReturnConfirmedAt != null;

            if (alreadyConfirmed) {
              return const Result<Booking>.failure(
                ValidationFailure('You have already confirmed the return.'),
              );
            }

            final now = _clock.now();

            final renterConfirmed =
                actor == BookingActor.renter ||
                booking.renterReturnConfirmedAt != null;

            final ownerConfirmed =
                actor == BookingActor.owner ||
                booking.ownerReturnConfirmedAt != null;

            final bothConfirmed = renterConfirmed && ownerConfirmed;

            final lockRef = _firestore.doc(
              '${FirestorePaths.renterLocks}/${booking.renterId}',
            );

            final lockSnapshot = bothConfirmed
                ? await transaction.get(lockRef)
                : null;

            // Normally released in startReturn; this covers returns started
            // before that change. A lock held by a newer booking is not ours
            // to release, so it is left alone.
            if (lockSnapshot != null &&
                lockSnapshot.exists &&
                lockSnapshot.data()?[FirestoreFields.bookingId] == booking.id) {
              transaction.delete(lockRef);
            }

            final updates = <String, dynamic>{
              FirestoreFields.updatedAt: Timestamp.fromDate(now),
            };

            if (actor == BookingActor.renter) {
              updates[FirestoreFields.renterReturnConfirmedAt] =
                  Timestamp.fromDate(now);
            } else {
              updates[FirestoreFields.ownerReturnConfirmedAt] =
                  Timestamp.fromDate(now);
            }

            final updatedBooking = booking.copyWith(
              renterReturnConfirmedAt: actor == BookingActor.renter
                  ? now
                  : booking.renterReturnConfirmedAt,
              ownerReturnConfirmedAt: actor == BookingActor.owner
                  ? now
                  : booking.ownerReturnConfirmedAt,
              updatedAt: now,
            );

            final write = FirestoreTransactionWrite(_firestore, transaction);

            if (bothConfirmed) {
              _notifications.send(
                write,
                userId: booking.renterId,
                type: NotificationType.returnConfirmed,
                title: 'Return inspection complete',
                text: 'Both parties confirmed the return. Waiting for the owner to settle the caution fee.',
                bookingId: booking.id,
              );

              _notifications.send(
                write,
                userId: booking.ownerId,
                type: NotificationType.returnConfirmed,
                title: 'Return inspection complete',
                text: 'Both parties confirmed the return. You can now settle the caution fee.',
                bookingId: booking.id,
              );
            } else {
              final otherPartyId = actor == BookingActor.renter
                  ? booking.ownerId
                  : booking.renterId;

              _notifications.send(
                write,
                userId: otherPartyId,
                type: NotificationType.returnConfirmed,
                title: 'Return confirmation',
                text: 'The other party has confirmed the vehicle return.',
                bookingId: booking.id,
              );
            }

            _audit.record(
              write,
              actorId: userId,
              entityType: 'booking',
              entityId: booking.id,
              oldState: booking.status.key,
              newState: updatedBooking.status.key,
            );

            transaction.update(bookingRef, updates);

            return Result.success(updatedBooking);
          })
          .timeout(_timeout);
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }

  @override
  Future<Result<Booking>> submitClaim({
    required String bookingId,
    required String userId,
    required int amount,
    required String reason,
    required List<String> evidenceUrls,
  }) async {
    if (_session.currentUserId != userId) {
      return const Result.failure(
        PermissionFailure('Sign in to submit a claim.'),
      );
    }

    if (bookingId.trim().isEmpty ||
        amount <= 0 ||
        reason.trim().isEmpty ||
        evidenceUrls.isEmpty) {
      return const Result.failure(
        ValidationFailure(
          'Enter a valid booking, amount, reason and evidence photo.',
        ),
      );
    }

    try {
      final bookingRef = _firestore.doc(FirestorePaths.booking(bookingId));
      final claimRef = _firestore.doc(_claimPath(bookingId));

      return await _firestore
          .runTransaction<Result<Booking>>((transaction) async {
            final bookingSnapshot = await transaction.get(bookingRef);
            final claimSnapshot = await transaction.get(claimRef);

            if (!bookingSnapshot.exists || bookingSnapshot.data() == null) {
              return const Result<Booking>.failure(
                NotFoundFailure('Booking not found.'),
              );
            }

            final booking = BookingModel.fromMap(
              bookingSnapshot.id,
              bookingSnapshot.data()!,
            );

            if (booking.ownerId != userId) {
              return const Result<Booking>.failure(
                PermissionFailure('Only the owner can submit a claim.'),
              );
            }

            if (booking.status != BookingStatus.returning) {
              return const Result<Booking>.failure(
                ValidationFailure('This booking is not awaiting a claim.'),
              );
            }

            if (booking.renterReturnConfirmedAt == null ||
                booking.ownerReturnConfirmedAt == null) {
              return const Result<Booking>.failure(
                ValidationFailure(
                  'Both parties must confirm the return before a claim.',
                ),
              );
            }

            if (claimSnapshot.exists) {
              return const Result<Booking>.failure(
                ValidationFailure('A claim already exists for this booking.'),
              );
            }

            final claimFailure = ClaimAmountPolicy.validateNewClaim(
              amount: amount,
              cautionFee: booking.cautionFee,
            );

            if (claimFailure != null) {
              return Result<Booking>.failure(claimFailure);
            }

            if (!_stateMachine.canTransition(
              booking.status,
              BookingStatus.review,
              BookingActor.owner,
            )) {
              return const Result<Booking>.failure(
                ValidationFailure('This booking cannot move to review.'),
              );
            }

            final now = _clock.now();

            final claim = CautionClaim(
              bookingId: booking.id,
              originalAmount: amount,
              currentAmount: amount,
              reason: reason.trim(),
              evidenceUrls: evidenceUrls,
              renterResponse: ClaimResponse.none,
              history: [
                ClaimHistoryEntry(
                  amount: amount,
                  reason: reason.trim(),
                  at: now,
                  response: ClaimResponse.none,
                ),
              ],
              status: ClaimStatus.open,
              updatedAt: now,
            );

            final updatedBooking = booking.copyWith(
              status: BookingStatus.review,
              cautionDecision: CautionDecision.claim,
              updatedAt: now,
            );

            final write = FirestoreTransactionWrite(_firestore, transaction);

            write.set(claimRef.path, CautionClaimModel.toMap(claim));

            transaction.update(bookingRef, {
              FirestoreFields.status: BookingStatus.review.key,
              FirestoreFields.cautionDecision: CautionDecision.claim.key,
              FirestoreFields.updatedAt: Timestamp.fromDate(now),
            });

            _notifications.send(
              write,
              userId: booking.renterId,
              type: NotificationType.claimChanged,
              title: 'Caution fee claim submitted',
              text: 'The owner submitted a claim. Please review it.',
              bookingId: booking.id,
            );

            _audit.record(
              write,
              actorId: userId,
              entityType: 'booking',
              entityId: booking.id,
              oldState: booking.status.key,
              newState: BookingStatus.review.key,
            );

            return Result.success(updatedBooking);
          })
          .timeout(_timeout);
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }

  @override
  Future<Result<Booking>> respondToClaim({
    required String bookingId,
    required String userId,
    required ClaimResponse response,
  }) async {
    if (_session.currentUserId != userId) {
      return const Result.failure(
        PermissionFailure('Sign in to respond to this claim.'),
      );
    }

    if (response == ClaimResponse.none) {
      return const Result.failure(
        ValidationFailure('Choose agree or dispute.'),
      );
    }

    try {
      final bookingRef = _firestore.doc(FirestorePaths.booking(bookingId));
      final claimRef = _firestore.doc(_claimPath(bookingId));

      return await _firestore
          .runTransaction<Result<Booking>>((transaction) async {
            final bookingSnapshot = await transaction.get(bookingRef);
            final claimSnapshot = await transaction.get(claimRef);

            if (!bookingSnapshot.exists || bookingSnapshot.data() == null) {
              return const Result<Booking>.failure(
                NotFoundFailure('Booking not found.'),
              );
            }

            if (!claimSnapshot.exists || claimSnapshot.data() == null) {
              return const Result<Booking>.failure(
                NotFoundFailure('Caution claim not found.'),
              );
            }

            final booking = BookingModel.fromMap(
              bookingSnapshot.id,
              bookingSnapshot.data()!,
            );

            final claim = CautionClaimModel.fromMap(
              claimSnapshot.id,
              claimSnapshot.data()!,
            );

            if (booking.renterId != userId) {
              return const Result<Booking>.failure(
                PermissionFailure('Only the renter can respond to this claim.'),
              );
            }

            if (booking.status != BookingStatus.review ||
                claim.status != ClaimStatus.open) {
              return const Result<Booking>.failure(
                ValidationFailure('This claim is not open for a response.'),
              );
            }

            if (claim.renterResponse != ClaimResponse.none) {
              return const Result<Booking>.failure(
                ValidationFailure('You have already responded to this claim.'),
              );
            }

            final now = _clock.now();

            final updatedClaim = claim.copyWith(
              renterResponse: response,
              history: [
                ...claim.history,
                ClaimHistoryEntry(
                  amount: claim.currentAmount,
                  reason: claim.reason,
                  at: now,
                  response: response,
                ),
              ],
              updatedAt: now,
            );

            final write = FirestoreTransactionWrite(_firestore, transaction);

            if (response == ClaimResponse.disputed) {
              write.set(claimRef.path, CautionClaimModel.toMap(updatedClaim));

              transaction.update(bookingRef, {
                FirestoreFields.updatedAt: Timestamp.fromDate(now),
              });

              _notifications.send(
                write,
                userId: booking.ownerId,
                type: NotificationType.claimChanged,
                title: 'Caution claim disputed',
                text: 'The renter has disputed your caution fee claim.',
                bookingId: booking.id,
              );

              _audit.record(
                write,
                actorId: userId,
                entityType: 'cautionClaim',
                entityId: booking.id,
                oldState: ClaimResponse.none.key,
                newState: ClaimResponse.disputed.key,
              );

              return Result.success(booking.copyWith(updatedAt: now));
            }

            if (!_stateMachine.canTransition(
              booking.status,
              BookingStatus.completed,
              BookingActor.renter,
            )) {
              return const Result<Booking>.failure(
                ValidationFailure('This booking cannot be completed.'),
              );
            }

            final returnedAt = booking.returnedAt;

            if (returnedAt == null) {
              return const Result<Booking>.failure(
                ValidationFailure('The return time is missing.'),
              );
            }

            final settlementResult = CautionSettlementCalculator.forAgreedClaim(
              rentalFee: booking.rentalFee,
              cautionFee: booking.cautionFee,
              dueAt: booking.endDate,
              returnedAt: returnedAt,
              claimAmount: claim.currentAmount,
              lateFeeWaived: booking.lateFeeWaived,
              ownerAdjustedFee: LateFeeCalculator.ownerAdjustedFeeOf(
                booking.lateFee,
              ),
            );

            if (settlementResult case Failure<CautionSettlement>(
              :final failure,
            )) {
              return Result<Booking>.failure(failure);
            }

            final settlement =
                (settlementResult as Success<CautionSettlement>).value;
            final lateDays = settlement.lateDays;
            final lateFee = settlement.lateFee;

            final updatedBooking = booking.copyWith(
              status: BookingStatus.completed,
              lateDays: lateDays,
              lateFee: lateFee,
              completedAt: now,
              updatedAt: now,
            );

            final settledClaim = updatedClaim.copyWith(
              status: ClaimStatus.settled,
              updatedAt: now,
            );

            write.set(claimRef.path, CautionClaimModel.toMap(settledClaim));

            _completion.write(
              write,
              completed: updatedBooking,
              settlement: settlement,
              path: CompletionPath.agreedClaim,
            );

            transaction.update(bookingRef, {
              FirestoreFields.status: BookingStatus.completed.key,
              FirestoreFields.lateDays: lateDays,
              FirestoreFields.lateFee: lateFee,
              FirestoreFields.completedAt: Timestamp.fromDate(now),
              FirestoreFields.updatedAt: Timestamp.fromDate(now),
            });

            _audit.record(
              write,
              actorId: userId,
              entityType: 'booking',
              entityId: booking.id,
              oldState: BookingStatus.review.key,
              newState: BookingStatus.completed.key,
            );

            return Result.success(updatedBooking);
          })
          .timeout(_timeout);
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }

  @override
  Future<Result<Booking>> reviseClaim({
    required String bookingId,
    required String userId,
    required int amount,
    required String reason,
    required List<String> evidenceUrls,
  }) async {
    if (_session.currentUserId != userId) {
      return const Result.failure(
        PermissionFailure('Sign in to revise this claim.'),
      );
    }

    if (amount <= 0 || reason.trim().isEmpty || evidenceUrls.isEmpty) {
      return const Result.failure(
        ValidationFailure('Enter a valid amount, reason and evidence photo.'),
      );
    }

    try {
      final bookingRef = _firestore.doc(FirestorePaths.booking(bookingId));
      final claimRef = _firestore.doc(_claimPath(bookingId));

      return await _firestore
          .runTransaction<Result<Booking>>((transaction) async {
            final bookingSnapshot = await transaction.get(bookingRef);
            final claimSnapshot = await transaction.get(claimRef);

            if (!bookingSnapshot.exists || bookingSnapshot.data() == null) {
              return const Result<Booking>.failure(
                NotFoundFailure('Booking not found.'),
              );
            }

            if (!claimSnapshot.exists || claimSnapshot.data() == null) {
              return const Result<Booking>.failure(
                NotFoundFailure('Caution claim not found.'),
              );
            }

            final booking = BookingModel.fromMap(
              bookingSnapshot.id,
              bookingSnapshot.data()!,
            );

            final claim = CautionClaimModel.fromMap(
              claimSnapshot.id,
              claimSnapshot.data()!,
            );

            if (booking.ownerId != userId) {
              return const Result<Booking>.failure(
                PermissionFailure('Only the owner can revise a claim.'),
              );
            }

            if (booking.status != BookingStatus.review ||
                claim.status != ClaimStatus.open ||
                claim.renterResponse != ClaimResponse.disputed) {
              return const Result<Booking>.failure(
                ValidationFailure('This claim cannot currently be revised.'),
              );
            }

            final revisionFailure = ClaimAmountPolicy.validateRevision(
              amount: amount,
              currentAmount: claim.currentAmount,
              originalAmount: claim.originalAmount,
              cautionFee: booking.cautionFee,
            );

            if (revisionFailure != null) {
              return Result<Booking>.failure(revisionFailure);
            }

            final now = _clock.now();

            final updatedClaim = claim.copyWith(
              currentAmount: amount,
              reason: reason.trim(),
              evidenceUrls: evidenceUrls,
              renterResponse: ClaimResponse.none,
              history: [
                ...claim.history,
                ClaimHistoryEntry(
                  amount: amount,
                  reason: reason.trim(),
                  at: now,
                  response: ClaimResponse.none,
                ),
              ],
              updatedAt: now,
            );

            final write = FirestoreTransactionWrite(_firestore, transaction);

            write.set(claimRef.path, CautionClaimModel.toMap(updatedClaim));

            transaction.update(bookingRef, {
              FirestoreFields.updatedAt: Timestamp.fromDate(now),
            });

            _notifications.send(
              write,
              userId: booking.renterId,
              type: NotificationType.claimChanged,
              title: 'Caution claim revised',
              text: 'The owner has revised the claim. Please review it again.',
              bookingId: booking.id,
            );

            _audit.record(
              write,
              actorId: userId,
              entityType: 'cautionClaim',
              entityId: booking.id,
              oldState: ClaimResponse.disputed.key,
              newState: ClaimResponse.none.key,
            );

            return Result.success(booking.copyWith(updatedAt: now));
          })
          .timeout(_timeout);
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }

  @override
  Future<Result<Booking>> refundCaution({
    required String bookingId,
    required String userId,
  }) async {
    if (_session.currentUserId != userId) {
      return const Result.failure(
        PermissionFailure('Sign in to refund the caution fee.'),
      );
    }

    try {
      final bookingRef = _firestore.doc(FirestorePaths.booking(bookingId));
      final claimRef = _firestore.doc(_claimPath(bookingId));

      return await _firestore
          .runTransaction<Result<Booking>>((transaction) async {
            final bookingSnapshot = await transaction.get(bookingRef);
            final claimSnapshot = await transaction.get(claimRef);

            if (!bookingSnapshot.exists || bookingSnapshot.data() == null) {
              return const Result<Booking>.failure(
                NotFoundFailure('Booking not found.'),
              );
            }

            if (!claimSnapshot.exists || claimSnapshot.data() == null) {
              return const Result<Booking>.failure(
                NotFoundFailure('Caution claim not found.'),
              );
            }

            final booking = BookingModel.fromMap(
              bookingSnapshot.id,
              bookingSnapshot.data()!,
            );

            final claim = CautionClaimModel.fromMap(
              claimSnapshot.id,
              claimSnapshot.data()!,
            );

            if (booking.ownerId != userId) {
              return const Result<Booking>.failure(
                PermissionFailure('Only the owner can refund the caution fee.'),
              );
            }

            if (booking.status != BookingStatus.review ||
                claim.status != ClaimStatus.open) {
              return const Result<Booking>.failure(
                ValidationFailure('This claim cannot currently be refunded.'),
              );
            }

            if (!_stateMachine.canTransition(
              booking.status,
              BookingStatus.completed,
              BookingActor.owner,
            )) {
              return const Result<Booking>.failure(
                ValidationFailure('This booking cannot be completed.'),
              );
            }

            final returnedAt = booking.returnedAt;

            if (returnedAt == null) {
              return const Result<Booking>.failure(
                ValidationFailure('The return time is missing.'),
              );
            }

            final now = _clock.now();

            final settlementResult = CautionSettlementCalculator.forRefund(
              rentalFee: booking.rentalFee,
              cautionFee: booking.cautionFee,
              dueAt: booking.endDate,
              returnedAt: returnedAt,
              lateFeeWaived: booking.lateFeeWaived,
              ownerAdjustedFee: LateFeeCalculator.ownerAdjustedFeeOf(
                booking.lateFee,
              ),
            );

            if (settlementResult case Failure<CautionSettlement>(
              :final failure,
            )) {
              return Result<Booking>.failure(failure);
            }

            final settlement =
                (settlementResult as Success<CautionSettlement>).value;
            final lateDays = settlement.lateDays;
            final lateFee = settlement.lateFee;

            final updatedBooking = booking.copyWith(
              status: BookingStatus.completed,
              lateDays: lateDays,
              lateFee: lateFee,
              completedAt: now,
              updatedAt: now,
            );

            final refundedClaim = claim.copyWith(
              status: ClaimStatus.refunded,
              updatedAt: now,
            );

            final write = FirestoreTransactionWrite(_firestore, transaction);

            write.set(claimRef.path, CautionClaimModel.toMap(refundedClaim));

            _completion.write(
              write,
              completed: updatedBooking,
              settlement: settlement,
              path: CompletionPath.refund,
            );

            transaction.update(bookingRef, {
              FirestoreFields.status: BookingStatus.completed.key,
              FirestoreFields.lateDays: lateDays,
              FirestoreFields.lateFee: lateFee,
              FirestoreFields.completedAt: Timestamp.fromDate(now),
              FirestoreFields.updatedAt: Timestamp.fromDate(now),
            });

            _audit.record(
              write,
              actorId: userId,
              entityType: 'booking',
              entityId: booking.id,
              oldState: BookingStatus.review.key,
              newState: BookingStatus.completed.key,
            );

            return Result.success(updatedBooking);
          })
          .timeout(_timeout);
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }

  @override
  Future<Result<Booking>> markNoIssue({
    required String bookingId,
    required String userId,
  }) async {
    if (_session.currentUserId != userId) {
      return const Result<Booking>.failure(
        PermissionFailure('Sign in to settle the caution fee.'),
      );
    }

    try {
      final bookingRef = _firestore.doc(FirestorePaths.booking(bookingId));
      final claimRef = _firestore.doc(_claimPath(bookingId));

      return await _firestore
          .runTransaction<Result<Booking>>((transaction) async {
            final bookingSnapshot = await transaction.get(bookingRef);
            final claimSnapshot = await transaction.get(claimRef);

            if (!bookingSnapshot.exists || bookingSnapshot.data() == null) {
              return const Result<Booking>.failure(
                NotFoundFailure('Booking not found.'),
              );
            }

            final booking = BookingModel.fromMap(
              bookingSnapshot.id,
              bookingSnapshot.data()!,
            );

            if (booking.ownerId != userId) {
              return const Result<Booking>.failure(
                PermissionFailure('Only the owner can settle the caution.'),
              );
            }

            if (booking.status != BookingStatus.returning) {
              return const Result<Booking>.failure(
                ValidationFailure('This booking is not awaiting settlement.'),
              );
            }

            if (booking.renterReturnConfirmedAt == null ||
                booking.ownerReturnConfirmedAt == null) {
              return const Result<Booking>.failure(
                ValidationFailure(
                  'Both parties must confirm the return first.',
                ),
              );
            }

            if (booking.returnedAt == null) {
              return const Result<Booking>.failure(
                ValidationFailure('The return time is missing.'),
              );
            }

            if (claimSnapshot.exists) {
              return const Result<Booking>.failure(
                ValidationFailure(
                  'A caution claim already exists for this booking.',
                ),
              );
            }

            if (!_stateMachine.canTransition(
              booking.status,
              BookingStatus.review,
              BookingActor.owner,
            )) {
              return const Result<Booking>.failure(
                ValidationFailure('This booking cannot move to review.'),
              );
            }

            final now = _clock.now();

            final updatedBooking = booking.copyWith(
              status: BookingStatus.review,
              cautionDecision: CautionDecision.noIssue,
              updatedAt: now,
            );

            final write = FirestoreTransactionWrite(_firestore, transaction);

            transaction.update(bookingRef, {
              FirestoreFields.status: BookingStatus.review.key,
              FirestoreFields.cautionDecision: CautionDecision.noIssue.key,
              FirestoreFields.updatedAt: Timestamp.fromDate(now),
            });

            _notifications.send(
              write,
              userId: booking.renterId,
              type: NotificationType.returnConfirmed,
              title: 'No damage reported',
              text: 'The owner found no issues with the vehicle. Please acknowledge the caution settlement.',
              bookingId: booking.id,
            );

            _audit.record(
              write,
              actorId: userId,
              entityType: 'booking',
              entityId: booking.id,
              oldState: BookingStatus.returning.key,
              newState: BookingStatus.review.key,
            );

            return Result.success(updatedBooking);
          })
          .timeout(_timeout);
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }

  @override
  Future<Result<Booking>> acknowledgeNoIssue({
    required String bookingId,
    required String userId,
  }) async {
    if (_session.currentUserId != userId) {
      return const Result<Booking>.failure(
        PermissionFailure('Sign in to acknowledge the settlement.'),
      );
    }

    try {
      final bookingRef = _firestore.doc(FirestorePaths.booking(bookingId));

      return await _firestore
          .runTransaction<Result<Booking>>((transaction) async {
            final bookingSnapshot = await transaction.get(bookingRef);

            if (!bookingSnapshot.exists || bookingSnapshot.data() == null) {
              return const Result<Booking>.failure(
                NotFoundFailure('Booking not found.'),
              );
            }

            final booking = BookingModel.fromMap(
              bookingSnapshot.id,
              bookingSnapshot.data()!,
            );

            if (booking.renterId != userId) {
              return const Result<Booking>.failure(
                PermissionFailure(
                  'Only the renter can acknowledge settlement.',
                ),
              );
            }

            if (booking.status != BookingStatus.review ||
                booking.cautionDecision != CautionDecision.noIssue) {
              return const Result<Booking>.failure(
                ValidationFailure(
                  'This booking is not awaiting no-issue acknowledgement.',
                ),
              );
            }

            if (booking.renterOutcomeAckAt != null) {
              return const Result<Booking>.failure(
                ValidationFailure('You have already acknowledged settlement.'),
              );
            }

            if (booking.returnedAt == null) {
              return const Result<Booking>.failure(
                ValidationFailure('The return time is missing.'),
              );
            }

            if (booking.renterReturnConfirmedAt == null ||
                booking.ownerReturnConfirmedAt == null) {
              return const Result<Booking>.failure(
                ValidationFailure(
                  'Both parties must confirm the return first.',
                ),
              );
            }

            if (!_stateMachine.canTransition(
              booking.status,
              BookingStatus.completed,
              BookingActor.renter,
            )) {
              return const Result<Booking>.failure(
                ValidationFailure('This booking cannot be completed.'),
              );
            }

            final now = _clock.now();

            final settlementResult = CautionSettlementCalculator.forRefund(
              rentalFee: booking.rentalFee,
              cautionFee: booking.cautionFee,
              dueAt: booking.endDate,
              returnedAt: booking.returnedAt!,
              lateFeeWaived: booking.lateFeeWaived,
              ownerAdjustedFee: LateFeeCalculator.ownerAdjustedFeeOf(
                booking.lateFee,
              ),
            );

            if (settlementResult case Failure<CautionSettlement>(
              :final failure,
            )) {
              return Result<Booking>.failure(failure);
            }

            final settlement =
                (settlementResult as Success<CautionSettlement>).value;
            final lateDays = settlement.lateDays;
            final lateFee = settlement.lateFee;

            final updatedBooking = booking.copyWith(
              status: BookingStatus.completed,
              lateDays: lateDays,
              lateFee: lateFee,
              renterOutcomeAckAt: now,
              completedAt: now,
              updatedAt: now,
            );

            final write = FirestoreTransactionWrite(_firestore, transaction);

            _completion.write(
              write,
              completed: updatedBooking,
              settlement: settlement,
              path: CompletionPath.noIssue,
            );

            transaction.update(bookingRef, {
              FirestoreFields.status: BookingStatus.completed.key,
              FirestoreFields.lateDays: lateDays,
              FirestoreFields.lateFee: lateFee,
              FirestoreFields.renterOutcomeAckAt: Timestamp.fromDate(now),
              FirestoreFields.completedAt: Timestamp.fromDate(now),
              FirestoreFields.updatedAt: Timestamp.fromDate(now),
            });

            _audit.record(
              write,
              actorId: userId,
              entityType: 'booking',
              entityId: booking.id,
              oldState: BookingStatus.review.key,
              newState: BookingStatus.completed.key,
            );

            return Result.success(updatedBooking);
          })
          .timeout(_timeout);
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }

  @override
  Future<Result<Booking>> adjustLateFee({
    required String bookingId,
    required String userId,
    bool waived = false,
    int? reducedFee,
  }) async {
    if (_session.currentUserId != userId) {
      return const Result.failure(
        PermissionFailure('Sign in to change the late fee.'),
      );
    }

    if (waived && reducedFee != null) {
      return const Result.failure(
        ValidationFailure('Choose either waive or reduce.'),
      );
    }

    if (reducedFee != null && reducedFee <= 0) {
      return const Result.failure(
        ValidationFailure('Enter a reduced fee above 0, or waive the fee.'),
      );
    }

    try {
      final bookingRef = _firestore.doc(FirestorePaths.booking(bookingId));

      return await _firestore
          .runTransaction<Result<Booking>>((transaction) async {
            final snapshot = await transaction.get(bookingRef);

            if (!snapshot.exists || snapshot.data() == null) {
              return const Result<Booking>.failure(
                NotFoundFailure('Booking not found.'),
              );
            }

            final booking = BookingModel.fromMap(snapshot.id, snapshot.data()!);

            if (booking.ownerId != userId) {
              return const Result<Booking>.failure(
                PermissionFailure('Only the owner can change the late fee.'),
              );
            }

            if (booking.status != BookingStatus.returning ||
                booking.returnedAt == null) {
              return const Result<Booking>.failure(
                ValidationFailure(
                  'The late fee can only be changed during the return.',
                ),
              );
            }

            if (reducedFee != null) {
              final lateDays = LateFeeCalculator.calculateLateDays(
                dueAt: booking.endDate,
                returnedAt: booking.returnedAt!,
              );
              final calculated = LateFeeCalculator.calculateLateFee(
                rentalFee: booking.rentalFee,
                lateDays: lateDays,
                cautionFee: booking.cautionFee,
              );

              if (reducedFee > calculated) {
                return Result<Booking>.failure(
                  ValidationFailure(
                    'The reduced fee cannot exceed the late fee ($calculated RWF).',
                  ),
                );
              }
            }

            final now = _clock.now();
            final storedFee = reducedFee ?? 0;

            transaction.update(bookingRef, {
              FirestoreFields.lateFeeWaived: waived,
              FirestoreFields.lateFee: storedFee,
              FirestoreFields.updatedAt: Timestamp.fromDate(now),
            });

            return Result.success(
              booking.copyWith(
                lateFeeWaived: waived,
                lateFee: storedFee,
                updatedAt: now,
              ),
            );
          })
          .timeout(_timeout);
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }
}
