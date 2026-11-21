import 'dart:typed_data';

import '../../../../core/domain/entities/repair_expense.dart';
import '../../../../core/error/result.dart';

abstract interface class RepairExpenseRepository {
  Stream<List<RepairExpense>> watchExpenses({
    required String bookingId,
    required String ownerId,
  });

  /// Creates an expense, or updates [existing]. A new receipt photo
  /// ([receiptBytes]) replaces the stored one; without it the existing
  /// receipt stays. An expense always needs a receipt.
  Future<Result<RepairExpense>> saveExpense({
    RepairExpense? existing,
    required String bookingId,
    required String vehicleId,
    required String ownerId,
    required int amount,
    required String description,
    Uint8List? receiptBytes,
    String receiptExtension = 'jpg',
  });

  Future<Result<void>> deleteExpense(RepairExpense expense);
}
