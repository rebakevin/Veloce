import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:veloce/core/constants/app_constants.dart';
import 'package:veloce/core/constants/firestore_paths.dart';
import 'package:veloce/core/data/models/booking_contact_model.dart';
import 'package:veloce/core/data/models/booking_model.dart';
import 'package:veloce/core/data/models/contact_model.dart';
import 'package:veloce/core/data/services/failure_mapper.dart';
import 'package:veloce/core/domain/entities/booking.dart';
import 'package:veloce/core/domain/entities/booking_contact.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/domain/enums/checklist_side.dart';
import 'package:veloce/core/domain/enums/notification_type.dart';
import 'package:veloce/core/domain/services/atomic_write.dart';
import 'package:veloce/core/domain/services/audit_logger.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/domain/services/notification_writer.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/core/formatting/formatters.dart';

import '../domain/entities/booking_request_draft.dart';
import '../domain/repositories/request_repository.dart';

/// Writes the pending booking, its renter contact, the audit entry and the
/// owner notification in one batch.
class FirestoreRequestRepository implements RequestRepository {
  const FirestoreRequestRepository({
    required this._firestore,
    required this._writes,
    required this._audit,
    required this._notifications,
    required this._clock,
  });

  static const Duration _timeout = Duration(seconds: 20);

  final FirebaseFirestore _firestore;
  final AtomicWriteFactory _writes;
  final AuditLogger _audit;
  final NotificationWriter _notifications;
  final Clock _clock;

  @override
  Future<Result<bool>> hasActiveLock(String renterId) async {
    try {
      final snapshot = await _firestore
          .doc('${FirestorePaths.renterLocks}/$renterId')
          .get()
          .timeout(_timeout);
      return Result.success(snapshot.exists);
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }

  @override
  Future<Result<Booking>> createBooking({
    required String renterId,
    required BookingRequestDraft draft,
  }) async {
    try {
      final contactSnapshot = await _firestore
          .doc(FirestorePaths.userPrivate(renterId, FirestorePaths.contactDoc))
          .get()
          .timeout(_timeout);
      final contactData = contactSnapshot.data();
      if (contactData == null) {
        return const Result.failure(
          ValidationFailure(
            'Add your phone and email to your profile before requesting a car.',
          ),
        );
      }
      final contact = ContactModel.fromMap(renterId, contactData);
      final now = _clock.now();
      final write = _writes.begin();
      final bookingId = write.newId(FirestorePaths.bookings);
      final reference = Formatters.bookingReference(
        1000 + (now.millisecondsSinceEpoch % 9000),
      );
      final vehicle = draft.vehicle;
      final quote = draft.quote;
      final booking = Booking(
        id: bookingId,
        reference: reference,
        vehicleId: vehicle.id,
        renterId: renterId,
        ownerId: vehicle.ownerId,
        startDate: draft.start,
        endDate: draft.end,
        days: quote.days,
        dailyRateApplied: quote.dailyRateApplied,
        rentalFee: quote.rentalFee,
        cautionFee: quote.cautionFee,
        platformFee: quote.platformFee,
        totalPayable: quote.totalPayable,
        status: BookingStatus.pending,
        reason: null,
        payDeadline: null,
        expiresAt: now.add(AppConstants.pendingExpiry),
        agreementAckAt: null,
        ownerPickupConfirmedAt: null,
        renterPickupConfirmedAt: null,
        returnedAt: null,
        ownerReturnConfirmedAt: null,
        renterReturnConfirmedAt: null,
        lateDays: 0,
        lateFee: 0,
        lateFeeWaived: false,
        cautionDecision: null,
        renterOutcomeAckAt: null,
        completedAt: null,
        createdAt: now,
        updatedAt: now,
      );
      write.set(FirestorePaths.booking(bookingId), BookingModel.toMap(booking));
      write.set(
        FirestorePaths.bookingPrivate(bookingId, ChecklistSide.renter.key),
        BookingContactModel.toMap(
          BookingContact(
            side: ChecklistSide.renter,
            bookingId: bookingId,
            phone: contact.phone,
            email: contact.email,
            meetingPoint: null,
          ),
        ),
      );
      _audit.record(
        write,
        actorId: renterId,
        entityType: 'booking',
        entityId: bookingId,
        oldState: null,
        newState: BookingStatus.pending.key,
      );
      _notifications.send(
        write,
        userId: vehicle.ownerId,
        type: NotificationType.requestReceived,
        title: 'New booking request',
        text:
            'A renter requested your ${vehicle.make} ${vehicle.model} '
            'for ${Formatters.dateRange(draft.start, draft.end)}.',
        bookingId: bookingId,
      );
      await write.commit().timeout(_timeout);
      return Result.success(booking);
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }
}
