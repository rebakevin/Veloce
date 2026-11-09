import 'package:equatable/equatable.dart';

/// A repair cost logged by an owner after a rental.
class RepairExpense extends Equatable {
  const RepairExpense({
    required this.id,
    required this.bookingId,
    required this.vehicleId,
    required this.ownerId,
    required this.amount,
    required this.description,
    required this.receiptUrl,
    required this.createdAt,
  });

  final String id;
  final String bookingId;
  final String vehicleId;
  final String ownerId;
  final int amount;
  final String description;
  final String? receiptUrl;
  final DateTime createdAt;

  RepairExpense copyWith({
    String? id,
    String? bookingId,
    String? vehicleId,
    String? ownerId,
    int? amount,
    String? description,
    String? receiptUrl,
    DateTime? createdAt,
  }) {
    return RepairExpense(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      vehicleId: vehicleId ?? this.vehicleId,
      ownerId: ownerId ?? this.ownerId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    bookingId,
    vehicleId,
    ownerId,
    amount,
    description,
    receiptUrl,
    createdAt,
  ];
}
