import '../entities/ledger_entry.dart';
import '../enums/transaction_status.dart';
import '../enums/transaction_type.dart';

/// Escrow arithmetic over a booking's ledger entries.
abstract final class LedgerBalance {
  /// Money Veloce still holds for a booking:
  /// `charge - release - refund - claim_deduction - late_fee`.
  /// Must never be negative, and is zero once the booking has ended.
  static int held(Iterable<LedgerEntry> entries) {
    var held = 0;
    for (final entry in entries) {
      if (entry.status != TransactionStatus.success) continue;
      held += switch (entry.type) {
        TransactionType.charge => entry.amount,
        TransactionType.release ||
        TransactionType.refund ||
        TransactionType.claimDeduction ||
        TransactionType.lateFee => -entry.amount,
        // Fee and payout are bookkeeping on money already released.
        TransactionType.platformFee || TransactionType.payout => 0,
      };
    }
    return held;
  }
}
