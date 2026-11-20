import 'dart:math';

import 'package:veloce/core/domain/entities/repair_expense.dart';

/// Turns repair costs into losses by offsetting the caution deducted from the
/// renter for the same booking (spec §5.2).
///
/// The deduction of a booking is one budget. The booking's repairs, oldest
/// first, consume it in turn, so a deduction is never offset twice when a
/// booking has several repair costs.
abstract final class RepairLossAllocator {
  /// The loss of each repair, keyed by repair id.
  static Map<String, int> allocate({
    required Iterable<RepairExpense> repairs,
    required Map<String, int> deductionByBooking,
  }) {
    final remaining = Map<String, int>.of(deductionByBooking);
    final ordered = repairs.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final losses = <String, int>{};
    for (final repair in ordered) {
      final budget = remaining[repair.bookingId] ?? 0;
      final offset = min(budget, repair.amount);
      remaining[repair.bookingId] = budget - offset;
      losses[repair.id] = repair.amount - offset;
    }
    return losses;
  }
}
