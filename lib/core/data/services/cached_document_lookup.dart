import 'package:cloud_firestore/cloud_firestore.dart';

import '../../error/app_failure.dart';
import '../../error/result.dart';
import 'failure_mapper.dart';

/// Read-by-id and live stream for one collection, with an in-memory cache.
/// [byId] returns the last known value; [watch] keeps the cache fresh.
class CachedDocumentLookup<T> {
  CachedDocumentLookup({
    required FirebaseFirestore firestore,
    required String collection,
    required this._fromMap,
  }) : _collection = firestore.collection(collection);

  final CollectionReference<Map<String, dynamic>> _collection;
  final T Function(String id, Map<String, dynamic> map) _fromMap;
  final Map<String, T> _cache = {};

  Future<Result<T>> byId(String id) async {
    final cached = _cache[id];
    if (cached != null) return Result.success(cached);
    try {
      return _resolve(await _collection.doc(id).get());
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }

  Stream<Result<T>> watch(String id) {
    return _collection
        .doc(id)
        .snapshots()
        .map(_resolve)
        .handleError(
          (Object error, StackTrace stackTrace) =>
              Result<T>.failure(mapToFailure(error, stackTrace)),
        );
  }

  /// Call on sign-out so the next user never sees another user's data.
  void clear() => _cache.clear();

  Result<T> _resolve(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) return const Result.failure(NotFoundFailure());
    final value = _fromMap(snapshot.id, data);
    _cache[snapshot.id] = value;
    return Result.success(value);
  }
}
