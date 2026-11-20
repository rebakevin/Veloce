import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import '../../domain/repositories/repair_expense_repository.dart';

enum RepairExpenseLoad { loading, loaded, failed }

enum RepairExpenseSave { idle, saving }

class RepairExpenseState extends Equatable {
  const RepairExpenseState({
    this.loadStatus = RepairExpenseLoad.loading,
    this.expenses = const [],
    this.saveStatus = RepairExpenseSave.idle,
    this.editing,
    this.receiptName,
    this.receiptBytes,
    this.errorMessage,
    this.notice,
  });

  final RepairExpenseLoad loadStatus;
  final List<RepairExpense> expenses;
  final RepairExpenseSave saveStatus;

  /// The expense being edited, or null when adding a new one.
  final RepairExpense? editing;

  /// A newly picked receipt photo, not yet uploaded.
  final String? receiptName;
  final Uint8List? receiptBytes;

  /// Inline form error.
  final String? errorMessage;

  /// One-off text for a snackbar (saved, deleted, delete failed).
  final String? notice;

  bool get isSaving => saveStatus == RepairExpenseSave.saving;

  bool get hasNewReceipt => receiptBytes != null;

  String? get existingReceiptUrl => editing?.receiptUrl;

  int get total =>
      expenses.fold<int>(0, (sum, expense) => sum + expense.amount);

  @override
  List<Object?> get props => [
    loadStatus,
    expenses,
    saveStatus,
    editing,
    receiptName,
    receiptBytes,
    errorMessage,
    notice,
  ];
}
