import 'package:veloce/core/domain/entities/ledger_entry.dart';
import 'package:veloce/core/domain/enums/transaction_type.dart';

/// What a renter sees a ledger row as in the payment history.
enum RenterPaymentKind {
  payment('Payment', isCredit: false),
  cautionRefund('Caution refund', isCredit: true),
  cancellationRefund('Cancellation refund', isCredit: true),
  claimDeduction('Claim deduction', isCredit: false),
  lateFee('Late fee', isCredit: false);

  const RenterPaymentKind(this.label, {required this.isCredit});

  final String label;

  /// Money comes back to the renter (true) or leaves the renter (false).
  final bool isCredit;

  /// Reference prefix the booking cancellation writes on its refund row.
  static const String cancellationReferencePrefix = 'REFUND-';

  /// The kind of [entry], or null for owner-side bookkeeping rows (release,
  /// platform fee, payout) that are not a renter payment.
  static RenterPaymentKind? classify(LedgerEntry entry) => switch (entry.type) {
    TransactionType.charge => payment,
    TransactionType.refund =>
      entry.reference.startsWith(cancellationReferencePrefix)
          ? cancellationRefund
          : cautionRefund,
    TransactionType.claimDeduction => claimDeduction,
    TransactionType.lateFee => lateFee,
    TransactionType.release ||
    TransactionType.platformFee ||
    TransactionType.payout => null,
  };
}
