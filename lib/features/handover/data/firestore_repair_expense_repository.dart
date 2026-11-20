import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:veloce/features/handover/domain/repositories/repair_expense_repository.dart';

class FirestoreRepairExpenseRepository implements RepairExpenseRepository {
  FirestoreRepairExpenseRepository({
    required this._firestore,
    required this._storage,
  });

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _expenses =>
      _firestore.collection('repairExpenses');

  @override
  Stream<List<RepairExpense>> watchExpenses({
    required String bookingId,
    required String ownerId,
  }) {
    return _expenses
        .where('bookingId', isEqualTo: bookingId)
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((document) {
            final data = document.data();

            return RepairExpense(
              id: document.id,
              bookingId: data['bookingId'] as String,
              ownerId: data['ownerId'] as String,
              amount: (data['amount'] as num).toInt(),
              description: data['description'] as String,
              receiptUrl: data['receiptUrl'] as String,
            );
          }).toList(),
        );
  }

  @override
  Future<void> saveExpense({
    String? expenseId,
    required String bookingId,
    required String ownerId,
    required int amount,
    required String description,
    Uint8List? receiptBytes,
    String? existingReceiptUrl,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('Repair expense amount must be greater than zero.');
    }

    if (description.trim().isEmpty) {
      throw ArgumentError('Repair expense description is required.');
    }

    final document = expenseId == null
        ? _expenses.doc()
        : _expenses.doc(expenseId);

    String? receiptUrl = existingReceiptUrl;

    if (receiptBytes != null) {
      final reference = _storage.ref().child(
        'repair-expenses/$bookingId/${document.id}.jpg',
      );

      await reference.putData(
        receiptBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      receiptUrl = await reference.getDownloadURL();
    }

    if (receiptUrl == null || receiptUrl.isEmpty) {
      throw ArgumentError('A receipt photo is required.');
    }

    final data = <String, dynamic>{
      'bookingId': bookingId,
      'ownerId': ownerId,
      'amount': amount,
      'description': description.trim(),
      'receiptUrl': receiptUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (expenseId == null) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    await document.set(data, SetOptions(merge: true));
  }

  @override
  Future<void> deleteExpense(RepairExpense expense) async {
    await _expenses.doc(expense.id).delete();

    try {
      await _storage.refFromURL(expense.receiptUrl).delete();
    } on Object {
      // The expense is deleted even if its receipt is unavailable.
    }
  }
}
