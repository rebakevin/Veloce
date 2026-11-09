import 'package:equatable/equatable.dart';

import '../enums/claim_response.dart';
import '../enums/claim_status.dart';
import 'claim_history_entry.dart';

/// An owner's claim against the caution. Doc id is the booking id.
class CautionClaim extends Equatable {
  const CautionClaim({
    required this.bookingId,
    required this.originalAmount,
    required this.currentAmount,
    required this.reason,
    required this.evidenceUrls,
    required this.renterResponse,
    required this.history,
    required this.status,
    required this.updatedAt,
  });

  final String bookingId;
  final int originalAmount;
  final int currentAmount;
  final String reason;
  final List<String> evidenceUrls;
  final ClaimResponse renterResponse;
  final List<ClaimHistoryEntry> history;
  final ClaimStatus status;
  final DateTime updatedAt;

  CautionClaim copyWith({
    String? bookingId,
    int? originalAmount,
    int? currentAmount,
    String? reason,
    List<String>? evidenceUrls,
    ClaimResponse? renterResponse,
    List<ClaimHistoryEntry>? history,
    ClaimStatus? status,
    DateTime? updatedAt,
  }) {
    return CautionClaim(
      bookingId: bookingId ?? this.bookingId,
      originalAmount: originalAmount ?? this.originalAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      reason: reason ?? this.reason,
      evidenceUrls: evidenceUrls ?? this.evidenceUrls,
      renterResponse: renterResponse ?? this.renterResponse,
      history: history ?? this.history,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    bookingId,
    originalAmount,
    currentAmount,
    reason,
    evidenceUrls,
    renterResponse,
    history,
    status,
    updatedAt,
  ];
}
