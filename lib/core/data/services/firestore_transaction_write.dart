import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/services/atomic_write.dart';

/// Allows existing writers to add records to a Firestore transaction.
class FirestoreTransactionWrite implements AtomicWrite {
  FirestoreTransactionWrite(this._firestore, this._transaction);

  final FirebaseFirestore _firestore;
  final Transaction _transaction;

  @override
  String newId(String collectionPath) {
    return _firestore.collection(collectionPath).doc().id;
  }

  @override
  void set(String documentPath, Map<String, dynamic> data) {
    _transaction.set(_firestore.doc(documentPath), data);
  }

  @override
  void update(String documentPath, Map<String, dynamic> data) {
    _transaction.update(_firestore.doc(documentPath), data);
  }

  @override
  void delete(String documentPath) {
    _transaction.delete(_firestore.doc(documentPath));
  }

  @override
  Future<void> commit() async {
    throw StateError('A Firestore transaction is committed by runTransaction.');
  }
}
