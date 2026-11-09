import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/firestore_fields.dart';
import '../../domain/entities/booking.dart';
import '../../domain/enums/booking_status.dart';
import '../../domain/enums/caution_decision.dart';
import 'wire.dart';

/// Maps [Booking] to and from the Firestore wire map.
abstract final class BookingModel {
  static Booking fromMap(String docId, Map<String, dynamic> map) {
    final wire = WireReader('Booking', map);
    return Booking(
      id: docId,
      reference: wire.string(FirestoreFields.reference),
      vehicleId: wire.string(FirestoreFields.vehicleId),
      renterId: wire.string(FirestoreFields.renterId),
      ownerId: wire.string(FirestoreFields.ownerId),
      startDate: wire.dateTime(FirestoreFields.startDate),
      endDate: wire.dateTime(FirestoreFields.endDate),
      days: wire.integer(FirestoreFields.days),
      dailyRateApplied: wire.integer(FirestoreFields.dailyRateApplied),
      rentalFee: wire.integer(FirestoreFields.rentalFee),
      cautionFee: wire.integer(FirestoreFields.cautionFee),
      platformFee: wire.integer(FirestoreFields.platformFee),
      totalPayable: wire.integer(FirestoreFields.totalPayable),
      status: wire.enumValue(FirestoreFields.status, BookingStatus.fromKey),
      reason: wire.optionalString(FirestoreFields.reason),
      payDeadline: wire.optionalDateTime(FirestoreFields.payDeadline),
      expiresAt: wire.optionalDateTime(FirestoreFields.expiresAt),
      agreementAckAt: wire.optionalDateTime(FirestoreFields.agreementAckAt),
      ownerPickupConfirmedAt: wire.optionalDateTime(
        FirestoreFields.ownerPickupConfirmedAt,
      ),
      renterPickupConfirmedAt: wire.optionalDateTime(
        FirestoreFields.renterPickupConfirmedAt,
      ),
      returnedAt: wire.optionalDateTime(FirestoreFields.returnedAt),
      ownerReturnConfirmedAt: wire.optionalDateTime(
        FirestoreFields.ownerReturnConfirmedAt,
      ),
      renterReturnConfirmedAt: wire.optionalDateTime(
        FirestoreFields.renterReturnConfirmedAt,
      ),
      lateDays: wire.integer(FirestoreFields.lateDays),
      lateFee: wire.integer(FirestoreFields.lateFee),
      lateFeeWaived: wire.boolean(FirestoreFields.lateFeeWaived),
      cautionDecision: wire.optionalEnum(
        FirestoreFields.cautionDecision,
        CautionDecision.fromKey,
      ),
      renterOutcomeAckAt: wire.optionalDateTime(
        FirestoreFields.renterOutcomeAckAt,
      ),
      completedAt: wire.optionalDateTime(FirestoreFields.completedAt),
      createdAt: wire.dateTime(FirestoreFields.createdAt),
      updatedAt: wire.dateTime(FirestoreFields.updatedAt),
    );
  }

  static Map<String, dynamic> toMap(Booking entity) => {
    FirestoreFields.reference: entity.reference,
    FirestoreFields.vehicleId: entity.vehicleId,
    FirestoreFields.renterId: entity.renterId,
    FirestoreFields.ownerId: entity.ownerId,
    FirestoreFields.startDate: Timestamp.fromDate(entity.startDate),
    FirestoreFields.endDate: Timestamp.fromDate(entity.endDate),
    FirestoreFields.days: entity.days,
    FirestoreFields.dailyRateApplied: entity.dailyRateApplied,
    FirestoreFields.rentalFee: entity.rentalFee,
    FirestoreFields.cautionFee: entity.cautionFee,
    FirestoreFields.platformFee: entity.platformFee,
    FirestoreFields.totalPayable: entity.totalPayable,
    FirestoreFields.status: entity.status.key,
    FirestoreFields.reason: entity.reason,
    FirestoreFields.payDeadline: timestampOrNull(entity.payDeadline),
    FirestoreFields.expiresAt: timestampOrNull(entity.expiresAt),
    FirestoreFields.agreementAckAt: timestampOrNull(entity.agreementAckAt),
    FirestoreFields.ownerPickupConfirmedAt: timestampOrNull(
      entity.ownerPickupConfirmedAt,
    ),
    FirestoreFields.renterPickupConfirmedAt: timestampOrNull(
      entity.renterPickupConfirmedAt,
    ),
    FirestoreFields.returnedAt: timestampOrNull(entity.returnedAt),
    FirestoreFields.ownerReturnConfirmedAt: timestampOrNull(
      entity.ownerReturnConfirmedAt,
    ),
    FirestoreFields.renterReturnConfirmedAt: timestampOrNull(
      entity.renterReturnConfirmedAt,
    ),
    FirestoreFields.lateDays: entity.lateDays,
    FirestoreFields.lateFee: entity.lateFee,
    FirestoreFields.lateFeeWaived: entity.lateFeeWaived,
    FirestoreFields.cautionDecision: entity.cautionDecision?.key,
    FirestoreFields.renterOutcomeAckAt: timestampOrNull(
      entity.renterOutcomeAckAt,
    ),
    FirestoreFields.completedAt: timestampOrNull(entity.completedAt),
    FirestoreFields.createdAt: Timestamp.fromDate(entity.createdAt),
    FirestoreFields.updatedAt: Timestamp.fromDate(entity.updatedAt),
  };
}
