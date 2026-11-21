import 'package:equatable/equatable.dart';
import 'package:veloce/core/domain/entities/ledger_entry.dart';

import '../enums/renter_payment_kind.dart';

/// Single item in renter payment history.
class RenterPaymentItem extends Equatable {
  const RenterPaymentItem({
    required this.entry,
    required this.kind,
    this.bookingReference,
    this.vehicleName,
  });

  final LedgerEntry entry;
  final RenterPaymentKind kind;
  final String? bookingReference;
  final String? vehicleName;

  @override
  List<Object?> get props => [entry, kind, bookingReference, vehicleName];
}
