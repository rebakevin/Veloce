import 'package:equatable/equatable.dart';
import 'package:veloce/core/domain/entities/ledger_entry.dart';

/// Single item in renter payment history.
class RenterPaymentItem extends Equatable {
  const RenterPaymentItem({
    required this.entry,
    this.bookingReference,
    this.vehicleName,
  });

  final LedgerEntry entry;
  final String? bookingReference;
  final String? vehicleName;

  @override
  List<Object?> get props => [entry, bookingReference, vehicleName];
}
