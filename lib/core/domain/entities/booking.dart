import 'package:equatable/equatable.dart';

import '../enums/booking_status.dart';
import '../enums/caution_decision.dart';

/// A rental request and its whole life cycle. Rate and totals are locked at request time.
class Booking extends Equatable {
  const Booking({
    required this.id,
    required this.reference,
    required this.vehicleId,
    required this.renterId,
    required this.ownerId,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.dailyRateApplied,
    required this.rentalFee,
    required this.cautionFee,
    required this.platformFee,
    required this.totalPayable,
    required this.status,
    required this.reason,
    required this.payDeadline,
    required this.expiresAt,
    required this.agreementAckAt,
    required this.ownerPickupConfirmedAt,
    required this.renterPickupConfirmedAt,
    required this.returnedAt,
    required this.ownerReturnConfirmedAt,
    required this.renterReturnConfirmedAt,
    required this.lateDays,
    required this.lateFee,
    required this.lateFeeWaived,
    required this.cautionDecision,
    required this.renterOutcomeAckAt,
    required this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String reference;
  final String vehicleId;
  final String renterId;
  final String ownerId;
  final DateTime startDate;
  final DateTime endDate;
  final int days;
  final int dailyRateApplied;
  final int rentalFee;
  final int cautionFee;
  final int platformFee;
  final int totalPayable;
  final BookingStatus status;
  final String? reason;
  final DateTime? payDeadline;
  final DateTime? expiresAt;
  final DateTime? agreementAckAt;
  final DateTime? ownerPickupConfirmedAt;
  final DateTime? renterPickupConfirmedAt;
  final DateTime? returnedAt;
  final DateTime? ownerReturnConfirmedAt;
  final DateTime? renterReturnConfirmedAt;
  final int lateDays;
  final int lateFee;
  final bool lateFeeWaived;
  final CautionDecision? cautionDecision;
  final DateTime? renterOutcomeAckAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Booking copyWith({
    String? id,
    String? reference,
    String? vehicleId,
    String? renterId,
    String? ownerId,
    DateTime? startDate,
    DateTime? endDate,
    int? days,
    int? dailyRateApplied,
    int? rentalFee,
    int? cautionFee,
    int? platformFee,
    int? totalPayable,
    BookingStatus? status,
    String? reason,
    DateTime? payDeadline,
    DateTime? expiresAt,
    DateTime? agreementAckAt,
    DateTime? ownerPickupConfirmedAt,
    DateTime? renterPickupConfirmedAt,
    DateTime? returnedAt,
    DateTime? ownerReturnConfirmedAt,
    DateTime? renterReturnConfirmedAt,
    int? lateDays,
    int? lateFee,
    bool? lateFeeWaived,
    CautionDecision? cautionDecision,
    DateTime? renterOutcomeAckAt,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Booking(
      id: id ?? this.id,
      reference: reference ?? this.reference,
      vehicleId: vehicleId ?? this.vehicleId,
      renterId: renterId ?? this.renterId,
      ownerId: ownerId ?? this.ownerId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      days: days ?? this.days,
      dailyRateApplied: dailyRateApplied ?? this.dailyRateApplied,
      rentalFee: rentalFee ?? this.rentalFee,
      cautionFee: cautionFee ?? this.cautionFee,
      platformFee: platformFee ?? this.platformFee,
      totalPayable: totalPayable ?? this.totalPayable,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      payDeadline: payDeadline ?? this.payDeadline,
      expiresAt: expiresAt ?? this.expiresAt,
      agreementAckAt: agreementAckAt ?? this.agreementAckAt,
      ownerPickupConfirmedAt:
          ownerPickupConfirmedAt ?? this.ownerPickupConfirmedAt,
      renterPickupConfirmedAt:
          renterPickupConfirmedAt ?? this.renterPickupConfirmedAt,
      returnedAt: returnedAt ?? this.returnedAt,
      ownerReturnConfirmedAt:
          ownerReturnConfirmedAt ?? this.ownerReturnConfirmedAt,
      renterReturnConfirmedAt:
          renterReturnConfirmedAt ?? this.renterReturnConfirmedAt,
      lateDays: lateDays ?? this.lateDays,
      lateFee: lateFee ?? this.lateFee,
      lateFeeWaived: lateFeeWaived ?? this.lateFeeWaived,
      cautionDecision: cautionDecision ?? this.cautionDecision,
      renterOutcomeAckAt: renterOutcomeAckAt ?? this.renterOutcomeAckAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    reference,
    vehicleId,
    renterId,
    ownerId,
    startDate,
    endDate,
    days,
    dailyRateApplied,
    rentalFee,
    cautionFee,
    platformFee,
    totalPayable,
    status,
    reason,
    payDeadline,
    expiresAt,
    agreementAckAt,
    ownerPickupConfirmedAt,
    renterPickupConfirmedAt,
    returnedAt,
    ownerReturnConfirmedAt,
    renterReturnConfirmedAt,
    lateDays,
    lateFee,
    lateFeeWaived,
    cautionDecision,
    renterOutcomeAckAt,
    completedAt,
    createdAt,
    updatedAt,
  ];
}
