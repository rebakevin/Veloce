import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/repair_expense_repository.dart';
import 'repair_expense_state.dart';

class RepairExpenseCubit extends Cubit<RepairExpenseState> {
  RepairExpenseCubit({
    required this.bookingId,
    required this.ownerId,
    required this._repository,
  }) : super(const RepairExpenseState()) {
    _subscription = _repository
        .watchExpenses(bookingId: bookingId, ownerId: ownerId)
        .listen(
          (expenses) => emit(
            _copy(loadStatus: RepairExpenseLoad.loaded, expenses: expenses),
          ),
          onError: (_) => emit(_copy(loadStatus: RepairExpenseLoad.failed)),
        );
  }

  final String bookingId;
  final String ownerId;
  final RepairExpenseRepository _repository;
  StreamSubscription<Object?>? _subscription;

  void receiptPicked({required String name, required Uint8List bytes}) {
    emit(_copy(receiptName: name, receiptBytes: bytes, clearError: true));
  }

  void startEditing(RepairExpense expense) {
    emit(
      _copy(
        editing: expense,
        clearReceipt: true,
        clearError: true,
        clearNotice: true,
      ),
    );
  }

  void clearForm() {
    emit(
      _copy(
        clearEditing: true,
        clearReceipt: true,
        clearError: true,
        clearNotice: true,
      ),
    );
  }

  Future<void> save({
    required String amountText,
    required String description,
  }) async {
    if (state.isSaving) return;

    final amount = int.tryParse(amountText.trim());
    final text = description.trim();

    if (amount == null || amount <= 0 || text.isEmpty) {
      emit(_copy(errorMessage: 'Enter a valid amount and description.'));
      return;
    }

    if (!state.hasNewReceipt && state.existingReceiptUrl == null) {
      emit(_copy(errorMessage: 'Please attach a receipt photo.'));
      return;
    }

    emit(
      _copy(
        saveStatus: RepairExpenseSave.saving,
        clearError: true,
        clearNotice: true,
      ),
    );

    try {
      await _repository.saveExpense(
        expenseId: state.editing?.id,
        bookingId: bookingId,
        ownerId: ownerId,
        amount: amount,
        description: text,
        receiptBytes: state.receiptBytes,
        existingReceiptUrl: state.existingReceiptUrl,
      );
      if (isClosed) return;

      emit(
        _copy(
          saveStatus: RepairExpenseSave.idle,
          clearEditing: true,
          clearReceipt: true,
          notice: 'Repair expense saved.',
        ),
      );
    } on Object catch (error) {
      if (isClosed) return;

      emit(
        _copy(
          saveStatus: RepairExpenseSave.idle,
          errorMessage: 'Could not save expense: $error',
        ),
      );
    }
  }

  Future<void> delete(RepairExpense expense) async {
    emit(_copy(clearNotice: true));

    try {
      await _repository.deleteExpense(expense);
      if (isClosed) return;

      final wasEditing = state.editing?.id == expense.id;
      emit(
        _copy(
          clearEditing: wasEditing,
          clearReceipt: wasEditing,
          clearError: wasEditing,
          notice: 'Repair expense deleted.',
        ),
      );
    } on Object catch (error) {
      if (isClosed) return;

      emit(_copy(notice: 'Could not delete expense: $error'));
    }
  }

  RepairExpenseState _copy({
    RepairExpenseLoad? loadStatus,
    List<RepairExpense>? expenses,
    RepairExpenseSave? saveStatus,
    RepairExpense? editing,
    bool clearEditing = false,
    String? receiptName,
    Uint8List? receiptBytes,
    bool clearReceipt = false,
    String? errorMessage,
    bool clearError = false,
    String? notice,
    bool clearNotice = false,
  }) {
    return RepairExpenseState(
      loadStatus: loadStatus ?? state.loadStatus,
      expenses: expenses ?? state.expenses,
      saveStatus: saveStatus ?? state.saveStatus,
      editing: clearEditing ? null : editing ?? state.editing,
      receiptName: clearReceipt ? null : receiptName ?? state.receiptName,
      receiptBytes: clearReceipt ? null : receiptBytes ?? state.receiptBytes,
      errorMessage: clearError ? null : errorMessage ?? state.errorMessage,
      notice: clearNotice ? null : notice ?? state.notice,
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
