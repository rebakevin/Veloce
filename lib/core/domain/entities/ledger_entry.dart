import 'package:equatable/equatable.dart';

import '../enums/party.dart';
import '../enums/transaction_status.dart';
import '../enums/transaction_type.dart';

/// One append-only money movement (the Firestore `transactions` collection).
class LedgerEntry extends Equatable {
  const LedgerEntry({
    required this.id,
    required this.bookingId,
    required this.vehicleId,
    required this.ownerId,
    required this.renterId,
    required this.type,
    required this.amount,
    required this.fromParty,
    required this.toParty,
    required this.reference,
    required this.status,
    required this.at,
  });

  final String id;
  final String bookingId;
  final String vehicleId;
  final String ownerId;
  final String renterId;
  final TransactionType type;
  final int amount;
  final Party fromParty;
  final Party toParty;
  final String reference;
  final TransactionStatus status;
  final DateTime at;

  LedgerEntry copyWith({
    String? id,
    String? bookingId,
    String? vehicleId,
    String? ownerId,
    String? renterId,
    TransactionType? type,
    int? amount,
    Party? fromParty,
    Party? toParty,
    String? reference,
    TransactionStatus? status,
    DateTime? at,
  }) {
    return LedgerEntry(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      vehicleId: vehicleId ?? this.vehicleId,
      ownerId: ownerId ?? this.ownerId,
      renterId: renterId ?? this.renterId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      fromParty: fromParty ?? this.fromParty,
      toParty: toParty ?? this.toParty,
      reference: reference ?? this.reference,
      status: status ?? this.status,
      at: at ?? this.at,
    );
  }

  @override
  List<Object?> get props => [
    id,
    bookingId,
    vehicleId,
    ownerId,
    renterId,
    type,
    amount,
    fromParty,
    toParty,
    reference,
    status,
    at,
  ];
}
