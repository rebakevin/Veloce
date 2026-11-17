import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veloce/core/constants/firestore_fields.dart';
import 'package:veloce/core/constants/firestore_paths.dart';
import 'package:veloce/core/data/services/failure_mapper.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/domain/services/atomic_write.dart';
import 'package:veloce/core/domain/services/media_storage.dart';
import 'package:veloce/core/error/result.dart';

import '../domain/repositories/account_eraser.dart';

typedef _Doc = DocumentSnapshot<Map<String, dynamic>>;

/// [AccountEraser] on Firestore. There is no backend to cascade deletes, so the
/// client finds every document by query and deletes it in batches.
///
/// A small account goes in one atomic batch. A large one is split: documents
/// whose security rules read their parent (a car's photos, a booking's
/// checklists, reviews of a booking) go first, then the bookings and cars, and
/// the user document last. Either way the erase deletes whatever exists, so
/// running it again after a failure finishes the job.
class FirestoreAccountEraser implements AccountEraser {
  const FirestoreAccountEraser({
    required this._firestore,
    required this._writes,
    required this._storage,
  });

  static const Duration _timeout = Duration(seconds: 30);

  /// Firestore allows 500 writes per batch.
  static const int _batchSize = 450;

  final FirebaseFirestore _firestore;
  final AtomicWriteFactory _writes;
  final MediaStorage _storage;

  @override
  Future<Result<void>> eraseAll(String uid) async {
    try {
      final plan = await _plan(uid);
      final user = FirestorePaths.user(uid);
      if (plan.size < _batchSize) {
        // One atomic batch, so a rejected delete leaves nothing half-deleted.
        // Rules read the state before the batch, so parents may go with their
        // children.
        await _delete([...plan.children, ...plan.parents, user]);
      } else {
        await _delete(plan.children);
        await _delete(plan.parents);
        await _delete([user]);
      }
      // Best effort: the storage policy may not allow deletes (MediaStorage).
      await Future.wait(plan.files.map(_storage.delete));
      return const Result.success(null);
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }

  Future<_Plan> _plan(String uid) async {
    final plan = _Plan();
    final user = FirestorePaths.user(uid);
    final vehicles = await _where(
      FirestorePaths.vehicles,
      FirestoreFields.ownerId,
      uid,
    );
    final bookings = {
      for (final field in [FirestoreFields.renterId, FirestoreFields.ownerId])
        for (final doc in await _where(FirestorePaths.bookings, field, uid))
          doc.id: doc,
    };

    for (final vehicle in vehicles) {
      plan.addParent(vehicle);
      for (final sub in [FirestorePaths.photos, FirestorePaths.documents]) {
        plan.addChildren(await _list('${vehicle.reference.path}/$sub'));
      }
      // Reviews of my cars, written by renters.
      plan.addChildren(
        await _where(
          FirestorePaths.reviews,
          FirestoreFields.subjectId,
          vehicle.id,
        ),
      );
    }

    for (final booking in bookings.values) {
      plan.addParent(booking);
      for (final sub in [
        FirestorePaths.checklistEntries,
        FirestorePaths.checklistMedia,
      ]) {
        plan.addChildren(await _list('${booking.reference.path}/$sub'));
      }
      final renterId = booking.data()?[FirestoreFields.renterId] as String;
      // Only my own side: the other party's contact copy is theirs.
      final mine = renterId == uid ? UserRole.renter : UserRole.owner;
      plan
        ..addChildPath(FirestorePaths.bookingPrivate(booking.id, mine.key))
        ..addChildPath('${FirestorePaths.calendarBlocks}/${booking.id}')
        ..addChildren([
          await _get('${FirestorePaths.cautionClaims}/${booking.id}'),
        ]);
      // The lock is keyed by renter, and only counts when it points here.
      final lock = await _get('${FirestorePaths.renterLocks}/$renterId');
      if (lock.data()?[FirestoreFields.bookingId] == booking.id) {
        plan.addChildren([lock]);
      }
    }

    for (final (collection, field) in [
      (FirestorePaths.reviews, FirestoreFields.authorId),
      (FirestorePaths.reviews, FirestoreFields.subjectId),
      (FirestorePaths.transactions, FirestoreFields.ownerId),
      (FirestorePaths.transactions, FirestoreFields.renterId),
      (FirestorePaths.repairExpenses, FirestoreFields.ownerId),
      (FirestorePaths.notifications, FirestoreFields.userId),
    ]) {
      plan.addChildren(await _where(collection, field, uid));
    }
    plan
      ..addChildren(await _list('$user/${FirestorePaths.favourites}'))
      ..addChildren(await _list('$user/${FirestorePaths.privateDocs}'))
      ..addUrlsOf(await _get(user));
    return plan;
  }

  Future<_Doc> _get(String path) =>
      _firestore.doc(path).get().timeout(_timeout);

  Future<List<_Doc>> _where(
    String collection,
    String field,
    String value,
  ) async {
    final snapshot = await _firestore
        .collection(collection)
        .where(field, isEqualTo: value)
        .get()
        .timeout(_timeout);
    return snapshot.docs;
  }

  Future<List<_Doc>> _list(String collection) async {
    final snapshot = await _firestore
        .collection(collection)
        .get()
        .timeout(_timeout);
    return snapshot.docs;
  }

  Future<void> _delete(Iterable<String> paths) async {
    final all = paths.toList();
    for (var start = 0; start < all.length; start += _batchSize) {
      final write = _writes.begin();
      all.skip(start).take(_batchSize).forEach(write.delete);
      await write.commit().timeout(_timeout);
    }
  }
}

/// What to delete, split by the order the security rules need.
class _Plan {
  static const String _publicUrlMarker = '/storage/v1/object/public/';

  /// Documents whose rules read a parent that must still exist.
  final Set<String> children = {};

  /// Bookings and cars.
  final Set<String> parents = {};

  /// Public file URLs found in the documents, for the best-effort cleanup.
  final Set<String> files = {};

  /// Documents to delete, including the user document.
  int get size => children.length + parents.length + 1;

  /// Missing documents are skipped, so callers can pass a `get` result as is.
  void addChildren(Iterable<_Doc> docs) {
    for (final doc in docs.where((doc) => doc.exists)) {
      children.add(doc.reference.path);
      addUrlsOf(doc);
    }
  }

  /// A document with no files to clean up, deleted without being read.
  void addChildPath(String path) => children.add(path);

  void addParent(_Doc doc) {
    parents.add(doc.reference.path);
    addUrlsOf(doc);
  }

  void addUrlsOf(_Doc doc) => _scan(doc.data());

  void _scan(Object? value) {
    switch (value) {
      case final String text when text.contains(_publicUrlMarker):
        files.add(text);
      case final Map<dynamic, dynamic> map:
        map.values.forEach(_scan);
      case final Iterable<dynamic> list:
        list.forEach(_scan);
    }
  }
}
