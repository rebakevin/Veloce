import 'dart:typed_data';

class RepairExpense {
  const RepairExpense({
    required this.id,
    required this.bookingId,
    required this.ownerId,
    required this.amount,
    required this.description,
    required this.receiptUrl,
  });

  final String id;
  final String bookingId;
  final String ownerId;
  final int amount;
  final String description;
  final String receiptUrl;
}

abstract class RepairExpenseRepository {
  Stream<List<RepairExpense>> watchExpenses({
    required String bookingId,
    required String ownerId,
  });

  Future<void> saveExpense({
    String? expenseId,
    required String bookingId,
    required String ownerId,
    required int amount,
    required String description,
    Uint8List? receiptBytes,
    String? existingReceiptUrl,
  });

  Future<void> deleteExpense(RepairExpense expense);
}
