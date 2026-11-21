import 'dart:math';

import 'package:veloce/core/domain/entities/ledger_entry.dart';
import 'package:veloce/core/domain/entities/repair_expense.dart';
import 'package:veloce/core/domain/enums/transaction_status.dart';
import 'package:veloce/core/domain/enums/transaction_type.dart';

import '../../../../core/constants/app_constants.dart';
import '../entities/finance_transaction.dart';
import 'repair_loss_allocator.dart';

/// Turns ledger rows and repair expenses into the owner's earned and loss
/// entries for one period. Pure: the repository only fetches the rows.
abstract final class OwnerFinanceCalculator {
  /// Platform fee assumed for a release that has no `platform_fee` row.
  static const int fallbackPlatformFee = AppConstants.platformFee;

  /// Entries of `[periodStart, periodEnd)`, newest first, without vehicle
  /// names. When [vehicleId] is set only that car counts.
  static List<FinanceTransaction> build({
    required Iterable<LedgerEntry> ledger,
    required Iterable<RepairExpense> repairs,
    required DateTime periodStart,
    required DateTime periodEnd,
    String? vehicleId,
  }) {
    final settled = ledger
        .where((entry) => entry.status == TransactionStatus.success)
        .toList();

    final feeByBooking = <String, int>{};
    final deductionByBooking = <String, int>{};
    for (final entry in settled) {
      if (entry.type == TransactionType.platformFee) {
        feeByBooking[entry.bookingId] =
            (feeByBooking[entry.bookingId] ?? 0) + entry.amount;
      } else if (entry.type == TransactionType.claimDeduction) {
        deductionByBooking[entry.bookingId] =
            (deductionByBooking[entry.bookingId] ?? 0) + entry.amount;
      }
    }

    bool inPeriod(DateTime date) =>
        !date.isBefore(periodStart) && date.isBefore(periodEnd);

    final result = <FinanceTransaction>[];
    for (final entry in settled) {
      if (vehicleId != null && entry.vehicleId != vehicleId) continue;
      if (!inPeriod(entry.at)) continue;

      if (entry.type == TransactionType.release) {
        final fee = feeByBooking[entry.bookingId] ?? fallbackPlatformFee;
        result.add(_earned(entry, max(0, entry.amount - fee)));
      } else if (entry.type == TransactionType.lateFee) {
        result.add(_earned(entry, entry.amount));
      }
    }

    // The deduction of a booking is offset once across all its repairs, so
    // every repair is allocated first and the period filter comes after.
    final repairList = repairs.toList();
    final lossByRepair = RepairLossAllocator.allocate(
      repairs: repairList,
      deductionByBooking: deductionByBooking,
    );
    for (final repair in repairList) {
      if (vehicleId != null && repair.vehicleId != vehicleId) continue;
      if (!inPeriod(repair.createdAt)) continue;

      final loss = lossByRepair[repair.id] ?? 0;
      if (loss > 0) {
        result.add(
          FinanceTransaction(
            id: repair.id,
            bookingId: repair.bookingId,
            vehicleId: repair.vehicleId,
            type: FinanceEntryType.loss,
            amount: loss,
            date: repair.createdAt,
          ),
        );
      }
    }

    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  /// Share of a car in the total earned, 0 when nothing was earned.
  static double share({required int carEarned, required int totalEarned}) =>
      totalEarned > 0 ? carEarned / totalEarned : 0.0;

  static FinanceTransaction _earned(LedgerEntry entry, int amount) =>
      FinanceTransaction(
        id: entry.id,
        bookingId: entry.bookingId,
        vehicleId: entry.vehicleId,
        type: FinanceEntryType.earned,
        amount: amount,
        date: entry.at,
      );
}
