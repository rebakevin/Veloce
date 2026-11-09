import '../entities/booking.dart';
import '../enums/party.dart';
import '../enums/transaction_type.dart';
import 'atomic_write.dart';

/// Appends money movements to the ledger inside an [AtomicWrite].
///
/// Invariant: `held(booking) = charge - release - refund - claim_deduction
/// - late_fee >= 0`, and `0` once the booking is completed or cancelled.
abstract interface class LedgerWriter {
  void record(
    AtomicWrite write, {
    required Booking booking,
    required TransactionType type,
    required int amount,
    required Party from,
    required Party to,
    String reference,
  });
}
