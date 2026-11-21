import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veloce/core/constants/firestore_fields.dart';
import 'package:veloce/core/constants/firestore_paths.dart';
import 'package:veloce/core/data/services/failure_mapper.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/domain/services/atomic_write.dart';
import 'package:veloce/core/domain/services/media_storage.dart';
import 'package:veloce/core/error/result.dart';

import '../domain/repositories/account_eraser.dart';

/// A document found by the eraser: only what the plan needs.
class ErasableDoc {
  const ErasableDoc({required this.path, this.data});

  final String path;

  /// `null` when the document does not exist.
  final Map<String, dynamic>? data;

  bool get exists => data != null;

  String get id => path.split('/').last;
}

/// Reads documents for the eraser. Split from the batches so tests do not have
/// to fake the sealed Firestore snapshot classes.
abstract interface class ErasableDocSource {
  Future<List<ErasableDoc>> where(
    String collection,
    String field,
    String value,
  );

  Future<List<ErasableDoc>> list(String collectionPath);

  Future<ErasableDoc> get(String path);
}

/// [ErasableDocSource] on Firestore.
class FirestoreDocSource implements ErasableDocSource {
  const FirestoreDocSource(this._firestore);

  static const Duration _timeout = Duration(seconds: 30);

  final FirebaseFirestore _firestore;

  @override
  Future<List<ErasableDoc>> where(
    String collection,
    String field,
    String value,
  ) async {
    final snapshot = await _firestore
        .collection(collection)
        .where(field, isEqualTo: value)
        .get()
        .timeout(_timeout);
    return [
      for (final doc in snapshot.docs)
        ErasableDoc(path: doc.reference.path, data: doc.data()),
    ];
  }

  @override
  Future<List<ErasableDoc>> list(String collectionPath) async {
    final snapshot = await _firestore
        .collection(collectionPath)
        .get()
        .timeout(_timeout);
    return [
      for (final doc in snapshot.docs)
        ErasableDoc(path: doc.reference.path, data: doc.data()),
    ];
  }

  @override
  Future<ErasableDoc> get(String path) async {
    final doc = await _firestore.doc(path).get().timeout(_timeout);
    return ErasableDoc(path: path, data: doc.data());
  }
}

/// [AccountEraser] on Firestore. There is no backend to cascade deletes, so the
/// client finds every document by query and deletes it in batches.
///
/// The security rules read a document's parent while checking its delete, and
/// a batch may make at most 20 such reads. So the erase runs in small steps,
/// in this order:
///
/// 1. one unit per booking: checklist documents first, then the booking
///    together with its contact copy, calendar block, caution claim and renter
///    lock (those rules accept the delete only when the booking goes in the
///    same batch, or is already terminal);
/// 2. one unit per car: its photos, documents and received reviews, then the
///    car (the rules read the car before the batch, so it must still exist);
/// 3. ledger rows, repairs, notifications, reviews written or received;
/// 4. the user's favourites and private documents, then the user document.
///
/// Every step deletes whatever exists, so running the erase again after a
/// failure finishes the job.
class FirestoreAccountEraser implements AccountEraser {
  const FirestoreAccountEraser({
    required this._docs,
    required this._writes,
    required this._storage,
  });

  static const Duration _timeout = Duration(seconds: 30);

  /// Firestore allows 500 writes per batch.
  static const int _batchSize = 450;

  final ErasableDocSource _docs;
  final AtomicWriteFactory _writes;
  final MediaStorage _storage;

  @override
  Future<Result<void>> eraseAll(String uid) async {
    try {
      final plan = await _plan(uid);
      for (final batch in plan.batches) {
        await _commit(batch);
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

    for (final booking in bookings.values) {
      final checklists = <ErasableDoc>[
        for (final sub in [
          FirestorePaths.checklistEntries,
          FirestorePaths.checklistMedia,
        ])
          ...await _list('${booking.path}/$sub'),
      ];
      final renterId = booking.data?[FirestoreFields.renterId] as String;
      // Only my own side: the other party's contact copy is theirs.
      final mine = renterId == uid ? UserRole.renter : UserRole.owner;
      final claim = await _get('${FirestorePaths.cautionClaims}/${booking.id}');
      // The lock is keyed by renter, and only counts when it points here.
      final lock = await _get('${FirestorePaths.renterLocks}/$renterId');
      plan
        ..addUrlsOf(booking)
        ..addUnit(
          before: checklists,
          // Their rules need the booking gone in the same batch.
          withParent: [
            FirestorePaths.bookingPrivate(booking.id, mine.key),
            '${FirestorePaths.calendarBlocks}/${booking.id}',
            if (claim.exists) claim.path,
            if (lock.data?[FirestoreFields.bookingId] == booking.id) lock.path,
          ],
          parent: booking.path,
        );
      plan.addUrlsOf(claim);
    }

    for (final vehicle in vehicles) {
      final before = <ErasableDoc>[
        for (final sub in [FirestorePaths.photos, FirestorePaths.documents])
          ...await _list('${vehicle.path}/$sub'),
        // Reviews of my cars: their rules read the car, so it must still exist.
        ...await _where(
          FirestorePaths.reviews,
          FirestoreFields.subjectId,
          vehicle.id,
        ),
      ];
      plan
        ..addUrlsOf(vehicle)
        ..addUnit(before: before, withParent: const [], parent: vehicle.path);
    }

    for (final (collection, field) in [
      (FirestorePaths.transactions, FirestoreFields.ownerId),
      (FirestorePaths.transactions, FirestoreFields.renterId),
      (FirestorePaths.repairExpenses, FirestoreFields.ownerId),
      (FirestorePaths.notifications, FirestoreFields.userId),
      (FirestorePaths.reviews, FirestoreFields.authorId),
      (FirestorePaths.reviews, FirestoreFields.subjectId),
    ]) {
      plan.addLoose(await _where(collection, field, uid));
    }
    plan
      ..addLoose(await _list('$user/${FirestorePaths.favourites}'))
      ..addLoose(await _list('$user/${FirestorePaths.privateDocs}'))
      ..addUrlsOf(await _get(user));
    plan.flushLoose();
    plan.batches.add([user]);
    return plan;
  }

  Future<ErasableDoc> _get(String path) => _docs.get(path);

  Future<List<ErasableDoc>> _where(
    String collection,
    String field,
    String value,
  ) => _docs.where(collection, field, value);

  Future<List<ErasableDoc>> _list(String collection) => _docs.list(collection);

  Future<void> _commit(List<String> paths) async {
    final write = _writes.begin();
    paths.forEach(write.delete);
    await write.commit().timeout(_timeout);
  }
}

/// The batches to commit, in order.
class _Plan {
  static const String _publicUrlMarker = '/storage/v1/object/public/';
  static const int _max = FirestoreAccountEraser._batchSize;

  final List<List<String>> batches = [];

  /// Public file URLs found in the documents, for the best-effort cleanup.
  final Set<String> files = {};

  final Set<String> _seen = {};
  final List<String> _loose = [];

  /// A parent and what its rules need deleted with it. [before] documents only
  /// need the parent to exist, so they may go in earlier batches.
  void addUnit({
    required Iterable<ErasableDoc> before,
    required List<String> withParent,
    required String parent,
  }) {
    final early = [
      for (final doc in before)
        if (doc.exists && _seen.add(doc.path)) doc.path,
    ];
    before.forEach(addUrlsOf);
    final last = [...withParent.where(_seen.add), parent];
    var start = 0;
    while (early.length - start + last.length > _max) {
      final take = early.length - start > _max ? _max : early.length - start;
      batches.add(early.sublist(start, start + take));
      start += take;
    }
    batches.add([...early.sublist(start), ...last]);
  }

  /// Documents with no ordering needs, deleted after the units.
  void addLoose(Iterable<ErasableDoc> docs) {
    for (final doc in docs.where((doc) => doc.exists)) {
      if (_seen.add(doc.path)) _loose.add(doc.path);
      addUrlsOf(doc);
    }
  }

  void flushLoose() {
    for (var start = 0; start < _loose.length; start += _max) {
      batches.add(_loose.skip(start).take(_max).toList());
    }
  }

  void addUrlsOf(ErasableDoc doc) => _scan(doc.data);

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
