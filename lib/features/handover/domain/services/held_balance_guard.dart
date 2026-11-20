import 'package:veloce/core/domain/entities/ledger_entry.dart';
import 'package:veloce/core/domain/services/ledger_balance.dart';

/// The rule that Veloce never pays out more than it holds for a booking.
abstract final class HeldBalanceGuard {
  /// Held balance once [planned] entries are added to [existing].
  static int heldAfter({
    required Iterable<LedgerEntry> existing,
    required Iterable<LedgerEntry> planned,
  }) {
    return LedgerBalance.held([...existing, ...planned]);
  }

  /// True when the held balance stays at or above zero after [planned].
  static bool staysNonNegative({
    required Iterable<LedgerEntry> existing,
    required Iterable<LedgerEntry> planned,
  }) {
    return heldAfter(existing: existing, planned: planned) >= 0;
  }
}
