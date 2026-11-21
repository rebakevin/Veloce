import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/repair_expense.dart';
import '../../../../core/error/app_failure.dart';
import '../../domain/repositories/repair_expense_repository.dart';
import 'repair_expense_state.dart';

class RepairExpenseCubit extends Cubit<RepairExpenseState> {
  RepairExpenseCubit({
    required this.bookingId,
    required this.vehicleId,
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
  final String vehicleId;
  final String ownerId;
  final RepairExpenseRepository _repository;
  StreamSubscription<Object?>? _subscription;

  void receiptPicked({required String name, required Uint8List bytes}) {
    emit(
      _copy(
        receiptName: name,
        receiptBytes: bytes,
        receiptExtension: _extensionOf(name),
        clearError: true,
      ),
    );
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
      final result = await _repository.saveExpense(
        existing: state.editing,
        bookingId: bookingId,
        vehicleId: vehicleId,
        ownerId: ownerId,
        amount: amount,
        description: text,
        receiptBytes: state.receiptBytes,
        receiptExtension: state.receiptExtension,
      );
      if (isClosed) return;

      result.when(
        success: (_) => emit(
          _copy(
            saveStatus: RepairExpenseSave.idle,
            clearEditing: true,
            clearReceipt: true,
            notice: 'Repair expense saved.',
          ),
        ),
        failure: (failure) => emit(
          _copy(
            saveStatus: RepairExpenseSave.idle,
            errorMessage: failure.message,
          ),
        ),
      );
    } on Object {
      if (isClosed) return;

      emit(
        _copy(
          saveStatus: RepairExpenseSave.idle,
          errorMessage: const UnknownFailure().message,
        ),
      );
    }
  }

  Future<void> delete(RepairExpense expense) async {
    emit(_copy(clearNotice: true));

    try {
      final result = await _repository.deleteExpense(expense);
      if (isClosed) return;

      result.when(
        success: (_) {
          final wasEditing = state.editing?.id == expense.id;
          emit(
            _copy(
              clearEditing: wasEditing,
              clearReceipt: wasEditing,
              clearError: wasEditing,
              notice: 'Repair expense deleted.',
            ),
          );
        },
        failure: (failure) => emit(_copy(notice: failure.message)),
      );
    } on Object {
      if (isClosed) return;

      emit(_copy(notice: const UnknownFailure().message));
    }
  }

  static String _extensionOf(String name) =>
      name.contains('.') ? name.split('.').last.toLowerCase() : 'jpg';

  RepairExpenseState _copy({
    RepairExpenseLoad? loadStatus,
    List<RepairExpense>? expenses,
    RepairExpenseSave? saveStatus,
    RepairExpense? editing,
    bool clearEditing = false,
    String? receiptName,
    Uint8List? receiptBytes,
    String? receiptExtension,
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
      receiptExtension: receiptExtension ?? state.receiptExtension,
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
