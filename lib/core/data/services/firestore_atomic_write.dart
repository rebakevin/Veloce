import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/services/atomic_write.dart';

class FirestoreAtomicWrite implements AtomicWrite {
  FirestoreAtomicWrite(this._firestore) : _batch = _firestore.batch();

  final FirebaseFirestore _firestore;
  final WriteBatch _batch;

  @override
  String newId(String collectionPath) =>
      _firestore.collection(collectionPath).doc().id;

  @override
  void set(String documentPath, Map<String, dynamic> data) =>
      _batch.set(_firestore.doc(documentPath), data);

  @override
  void update(String documentPath, Map<String, dynamic> data) =>
      _batch.update(_firestore.doc(documentPath), data);

  @override
  void delete(String documentPath) =>
      _batch.delete(_firestore.doc(documentPath));

  @override
  Future<void> commit() => _batch.commit();
}

class FirestoreAtomicWriteFactory implements AtomicWriteFactory {
  const FirestoreAtomicWriteFactory(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  AtomicWrite begin() => FirestoreAtomicWrite(_firestore);
}
