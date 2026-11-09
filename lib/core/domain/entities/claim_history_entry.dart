import 'package:equatable/equatable.dart';

import '../enums/claim_response.dart';

/// One step in a caution claim's negotiation.
class ClaimHistoryEntry extends Equatable {
  const ClaimHistoryEntry({
    required this.amount,
    required this.reason,
    required this.at,
    required this.response,
  });

  final int amount;
  final String reason;
  final DateTime at;
  final ClaimResponse response;

  ClaimHistoryEntry copyWith({
    int? amount,
    String? reason,
    DateTime? at,
    ClaimResponse? response,
  }) {
    return ClaimHistoryEntry(
      amount: amount ?? this.amount,
      reason: reason ?? this.reason,
      at: at ?? this.at,
      response: response ?? this.response,
    );
  }

  @override
  List<Object?> get props => [amount, reason, at, response];
}
