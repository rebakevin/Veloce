import 'package:equatable/equatable.dart';

enum FinanceEntryType { earned, loss }

/// A single entry in the owner finances transaction list.
class FinanceTransaction extends Equatable {
  const FinanceTransaction({
    required this.id,
    required this.bookingId,
    required this.vehicleId,
    required this.type,
    required this.amount,
    required this.date,
    this.vehicleName,
    this.vehiclePlate,
  });

  final String id;
  final String bookingId;
  final String vehicleId;
  final FinanceEntryType type;
  final int amount; // Positive amount in RWF
  final DateTime date;
  final String? vehicleName;
  final String? vehiclePlate;

  @override
  List<Object?> get props => [
    id,
    bookingId,
    vehicleId,
    type,
    amount,
    date,
    vehicleName,
    vehiclePlate,
  ];
}
