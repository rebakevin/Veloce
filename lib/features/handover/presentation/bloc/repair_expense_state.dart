import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/repair_expense.dart';

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
    this.receiptExtension = 'jpg',
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
  final String receiptExtension;

  /// Inline form error.
  final String? errorMessage;

  /// One-off text for a snackbar (saved, deleted, delete failed).
  final String? notice;

  bool get isSaving => saveStatus == RepairExpenseSave.saving;

  bool get hasNewReceipt => receiptBytes != null;

  String? get existingReceiptUrl {
    final url = editing?.receiptUrl;
    return url == null || url.isEmpty ? null : url;
  }

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
    receiptExtension,
    errorMessage,
    notice,
  ];
}
