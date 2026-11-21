import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veloce/core/constants/firestore_fields.dart';
import 'package:veloce/core/constants/firestore_paths.dart';
import 'package:veloce/core/data/models/repair_expense_model.dart';
import 'package:veloce/core/data/services/failure_mapper.dart';
import 'package:veloce/core/domain/entities/repair_expense.dart';
import 'package:veloce/core/domain/enums/storage_bucket.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/domain/services/media_storage.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';

import '../domain/repositories/repair_expense_repository.dart';

/// Repair costs an owner logs for a booking. Receipts go to the Supabase
/// `receipts` bucket through [MediaStorage].
class FirestoreRepairExpenseRepository implements RepairExpenseRepository {
  const FirestoreRepairExpenseRepository({
    required this._firestore,
    required this._mediaStorage,
    required this._clock,
  });

  static const Duration _timeout = Duration(seconds: 20);

  final FirebaseFirestore _firestore;
  final MediaStorage _mediaStorage;
  final Clock _clock;

  CollectionReference<Map<String, dynamic>> get _expenses =>
      _firestore.collection(FirestorePaths.repairExpenses);

  @override
  Stream<List<RepairExpense>> watchExpenses({
    required String bookingId,
    required String ownerId,
  }) {
    return _expenses
        .where(FirestoreFields.bookingId, isEqualTo: bookingId)
        .where(FirestoreFields.ownerId, isEqualTo: ownerId)
        .snapshots()
        .map(
          (snapshot) => [
            for (final doc in snapshot.docs)
              RepairExpenseModel.fromMap(doc.id, doc.data()),
          ],
        );
  }

  @override
  Future<Result<RepairExpense>> saveExpense({
    RepairExpense? existing,
    required String bookingId,
    required String vehicleId,
    required String ownerId,
    required int amount,
    required String description,
    Uint8List? receiptBytes,
    String receiptExtension = 'jpg',
  }) async {
    if (amount <= 0) {
      return const Result.failure(
        ValidationFailure('Enter a repair amount above 0.'),
      );
    }

    if (description.trim().isEmpty) {
      return const Result.failure(
        ValidationFailure('Enter a description of the repair.'),
      );
    }

    final oldReceipt = existing?.receiptUrl;

    if (receiptBytes == null && (oldReceipt == null || oldReceipt.isEmpty)) {
      return const Result.failure(ValidationFailure('Attach a receipt photo.'));
    }

    try {
      var receiptUrl = oldReceipt;

      if (receiptBytes != null) {
        final uploaded = await _mediaStorage.upload(
          bytes: receiptBytes,
          extension: receiptExtension,
          bucket: StorageBucket.receipts,
        );

        switch (uploaded) {
          case Failure<String>(:final failure):
            return Result.failure(failure);
          case Success<String>(:final value):
            receiptUrl = value;
        }
      }

      final doc = existing == null
          ? _expenses.doc()
          : _expenses.doc(existing.id);

      final expense = RepairExpense(
        id: doc.id,
        bookingId: bookingId,
        vehicleId: vehicleId,
        ownerId: ownerId,
        amount: amount,
        description: description.trim(),
        receiptUrl: receiptUrl,
        createdAt: existing?.createdAt ?? _clock.now(),
      );

      await doc.set(RepairExpenseModel.toMap(expense)).timeout(_timeout);

      if (receiptBytes != null && oldReceipt != null && oldReceipt.isNotEmpty) {
        // Best effort: the replaced receipt may stay in storage.
        await _mediaStorage.delete(oldReceipt);
      }

      return Result.success(expense);
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }

  @override
  Future<Result<void>> deleteExpense(RepairExpense expense) async {
    try {
      await _expenses.doc(expense.id).delete().timeout(_timeout);

      final receipt = expense.receiptUrl;
      if (receipt != null && receipt.isNotEmpty) {
        // Best effort: the expense is gone even if the file stays.
        await _mediaStorage.delete(receipt);
      }

      return const Result.success(null);
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }
}
