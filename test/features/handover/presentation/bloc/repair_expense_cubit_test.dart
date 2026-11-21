import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/domain/entities/repair_expense.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/handover/presentation/bloc/repair_expense_cubit.dart';
import 'package:veloce/features/handover/presentation/bloc/repair_expense_state.dart';

import 'handover_fakes.dart';

void main() {
  late MockRepairExpenseRepository repository;
  late StreamController<List<RepairExpense>> expenses;

  final expense = RepairExpense(
    id: 'e1',
    bookingId: 'booking-1',
    vehicleId: 'car-1',
    ownerId: 'owner-1',
    amount: 15000,
    description: 'Door repaint',
    receiptUrl: 'https://example.com/receipt.jpg',
    createdAt: DateTime(2026, 11, 9),
  );

  setUp(() {
    repository = MockRepairExpenseRepository();
    expenses = StreamController<List<RepairExpense>>.broadcast();
    addTearDown(expenses.close);
    when(
      () =>
          repository.watchExpenses(bookingId: 'booking-1', ownerId: 'owner-1'),
    ).thenAnswer((_) => expenses.stream);
  });

  void stubSave() {
    when(
      () => repository.saveExpense(
        existing: any(named: 'existing'),
        bookingId: any(named: 'bookingId'),
        vehicleId: any(named: 'vehicleId'),
        ownerId: any(named: 'ownerId'),
        amount: any(named: 'amount'),
        description: any(named: 'description'),
        receiptBytes: any(named: 'receiptBytes'),
        receiptExtension: any(named: 'receiptExtension'),
      ),
    ).thenAnswer((_) async => Result.success(expense));
  }

  RepairExpenseCubit createCubit() {
    final cubit = RepairExpenseCubit(
      bookingId: 'booking-1',
      vehicleId: 'car-1',
      ownerId: 'owner-1',
      repository: repository,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  final receipt = Uint8List.fromList([1, 2, 3]);

  test('loads expenses from the stream and totals them', () async {
    final cubit = createCubit();
    expect(cubit.state.loadStatus, RepairExpenseLoad.loading);

    expenses.add([expense, expense]);
    await pumpEventQueue();

    expect(cubit.state.loadStatus, RepairExpenseLoad.loaded);
    expect(cubit.state.total, 30000);
  });

  test('a stream error becomes a failed load', () async {
    final cubit = createCubit();

    expenses.addError(Exception('boom'));
    await pumpEventQueue();

    expect(cubit.state.loadStatus, RepairExpenseLoad.failed);
  });

  group('save', () {
    test('rejects an invalid amount or description', () async {
      final cubit = createCubit();

      await cubit.save(amountText: '0', description: 'Door');
      expect(cubit.state.errorMessage, 'Enter a valid amount and description.');

      await cubit.save(amountText: '100', description: '  ');
      expect(cubit.state.errorMessage, 'Enter a valid amount and description.');
    });

    test('requires a receipt for a new expense', () async {
      final cubit = createCubit();

      await cubit.save(amountText: '100', description: 'Door');

      expect(cubit.state.errorMessage, 'Please attach a receipt photo.');
    });

    test(
      'saves a new expense with the picked receipt and resets the form',
      () async {
        stubSave();
        final cubit = createCubit()
          ..receiptPicked(name: 'r.jpg', bytes: receipt);

        await cubit.save(amountText: ' 15000 ', description: ' Door repaint ');

        verify(
          () => repository.saveExpense(
            existing: null,
            bookingId: 'booking-1',
            vehicleId: 'car-1',
            ownerId: 'owner-1',
            amount: 15000,
            description: 'Door repaint',
            receiptBytes: receipt,
            receiptExtension: 'jpg',
          ),
        ).called(1);
        expect(cubit.state.notice, 'Repair expense saved.');
        expect(cubit.state.hasNewReceipt, false);
        expect(cubit.state.isSaving, false);
      },
    );

    test('editing keeps the existing receipt when none is picked', () async {
      stubSave();
      final cubit = createCubit()..startEditing(expense);

      await cubit.save(amountText: '16000', description: 'Door repaint');

      verify(
        () => repository.saveExpense(
          existing: expense,
          bookingId: 'booking-1',
          vehicleId: 'car-1',
          ownerId: 'owner-1',
          amount: 16000,
          description: 'Door repaint',
          receiptBytes: null,
          receiptExtension: 'jpg',
        ),
      ).called(1);
      expect(cubit.state.editing, isNull);
    });

    test('a failed save keeps the form and shows the error', () async {
      when(
        () => repository.saveExpense(
          existing: any(named: 'existing'),
          bookingId: any(named: 'bookingId'),
          vehicleId: any(named: 'vehicleId'),
          ownerId: any(named: 'ownerId'),
          amount: any(named: 'amount'),
          description: any(named: 'description'),
          receiptBytes: any(named: 'receiptBytes'),
          receiptExtension: any(named: 'receiptExtension'),
        ),
      ).thenAnswer(
        (_) async => const Result.failure(NetworkFailure('Offline.')),
      );
      final cubit = createCubit()..receiptPicked(name: 'r.jpg', bytes: receipt);

      await cubit.save(amountText: '100', description: 'Door');

      expect(cubit.state.errorMessage, 'Offline.');
      expect(cubit.state.isSaving, false);
      expect(cubit.state.hasNewReceipt, true);
    });
  });

  group('delete', () {
    test('deletes and reports it', () async {
      when(() => repository.deleteExpense(expense))
          .thenAnswer((_) async => const Result<void>.success(null));
      final cubit = createCubit();

      await cubit.delete(expense);

      expect(cubit.state.notice, 'Repair expense deleted.');
    });

    test('clears the form when the edited expense is deleted', () async {
      when(() => repository.deleteExpense(expense))
          .thenAnswer((_) async => const Result<void>.success(null));
      final cubit = createCubit()..startEditing(expense);

      await cubit.delete(expense);

      expect(cubit.state.editing, isNull);
    });

    test('reports a failed delete', () async {
      when(() => repository.deleteExpense(expense)).thenAnswer(
        (_) async => const Result.failure(NetworkFailure('Offline.')),
      );
      final cubit = createCubit();

      await cubit.delete(expense);

      expect(cubit.state.notice, 'Offline.');
    });
  });

  test('clearForm drops the edit and the picked receipt', () {
    final cubit = createCubit()
      ..startEditing(expense)
      ..receiptPicked(name: 'r.jpg', bytes: receipt)
      ..clearForm();

    expect(cubit.state.editing, isNull);
    expect(cubit.state.hasNewReceipt, false);
  });
}
