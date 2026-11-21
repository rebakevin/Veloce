import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/domain/services/atomic_write.dart';
import 'package:veloce/core/domain/services/media_storage.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/profile/data/firestore_account_eraser.dart';

class _MockStorage extends Mock implements MediaStorage {}

/// Serves documents by `collection:field`, listed collection path or path.
class _FakeDocs implements ErasableDocSource {
  final Map<String, List<ErasableDoc>> byQuery = {};
  final Map<String, List<ErasableDoc>> byList = {};
  final Map<String, ErasableDoc> byPath = {};

  @override
  Future<List<ErasableDoc>> where(
    String collection,
    String field,
    String value,
  ) async => byQuery['$collection:$field'] ?? const [];

  @override
  Future<List<ErasableDoc>> list(String collectionPath) async =>
      byList[collectionPath] ?? const [];

  @override
  Future<ErasableDoc> get(String path) async =>
      byPath[path] ?? ErasableDoc(path: path);
}

class _RecordingWrites implements AtomicWriteFactory {
  final List<List<String>> batches = [];

  @override
  AtomicWrite begin() => _RecordingWrite(batches);
}

class _RecordingWrite implements AtomicWrite {
  _RecordingWrite(this._batches);

  final List<List<String>> _batches;
  final List<String> _deleted = [];

  @override
  String newId(String collectionPath) => 'id';

  @override
  void set(String documentPath, Map<String, dynamic> data) {}

  @override
  void update(String documentPath, Map<String, dynamic> data) {}

  @override
  void delete(String documentPath) => _deleted.add(documentPath);

  @override
  Future<void> commit() async => _batches.add(_deleted);
}

void main() {
  late _FakeDocs docs;
  late _RecordingWrites writes;
  late FirestoreAccountEraser eraser;

  ErasableDoc booking(String id) => ErasableDoc(
    path: 'bookings/$id',
    data: {'renterId': 'u1', 'ownerId': 'o1'},
  );

  setUp(() {
    docs = _FakeDocs();
    writes = _RecordingWrites();
    final storage = _MockStorage();
    when(() => storage.delete(any()))
        .thenAnswer((_) async => const Result.success(null));
    eraser = FirestoreAccountEraser(
      docs: docs,
      writes: writes,
      storage: storage,
    );
  });

  List<String> flat() => writes.batches.expand((batch) => batch).toList();

  int batchOf(String path) =>
      writes.batches.indexWhere((batch) => batch.contains(path));

  test('a booking goes with its block, claim, lock and own contact', () async {
    docs.byQuery['bookings:renterId'] = [booking('b1')];
    docs.byList['bookings/b1/checklistEntries'] = [
      const ErasableDoc(path: 'bookings/b1/checklistEntries/c1', data: {}),
    ];
    docs.byPath['cautionClaims/b1'] = const ErasableDoc(
      path: 'cautionClaims/b1',
      data: {'bookingId': 'b1'},
    );
    docs.byPath['renterLocks/u1'] = const ErasableDoc(
      path: 'renterLocks/u1',
      data: {'bookingId': 'b1'},
    );

    final result = await eraser.eraseAll('u1');

    expect(result, isA<Success<void>>());
    final unit = writes.batches[batchOf('bookings/b1')];
    expect(
      unit,
      containsAll([
        'bookings/b1/private/renter',
        'calendarBlocks/b1',
        'cautionClaims/b1',
        'renterLocks/u1',
        'bookings/b1/checklistEntries/c1',
      ]),
    );
    // Only my side of the contact copy.
    expect(flat(), isNot(contains('bookings/b1/private/owner')));
    expect(writes.batches.last, ['users/u1']);
  });

  test('a lock that points at another booking is left alone', () async {
    docs.byQuery['bookings:renterId'] = [booking('b1')];
    docs.byPath['renterLocks/u1'] = const ErasableDoc(
      path: 'renterLocks/u1',
      data: {'bookingId': 'other'},
    );

    await eraser.eraseAll('u1');

    expect(flat(), isNot(contains('renterLocks/u1')));
  });

  test('each booking and car has its own small batch', () async {
    docs.byQuery['bookings:renterId'] = [
      for (var i = 0; i < 30; i++) booking('b$i'),
    ];
    docs.byQuery['vehicles:ownerId'] = [
      const ErasableDoc(path: 'vehicles/v1', data: {'ownerId': 'u1'}),
    ];
    docs.byList['vehicles/v1/photos'] = [
      const ErasableDoc(path: 'vehicles/v1/photos/p1', data: {}),
    ];
    docs.byQuery['reviews:subjectId'] = [
      const ErasableDoc(path: 'reviews/r1', data: {}),
    ];

    await eraser.eraseAll('u1');

    for (var i = 0; i < 30; i++) {
      final unit = writes.batches[batchOf('bookings/b$i')];
      // Booking, block and contact copy: no other booking in the batch.
      expect(unit.where((p) => p.startsWith('bookings/b$i')), hasLength(2));
      expect(
        unit.where((p) => RegExp(r'^bookings/b\d+$').hasMatch(p)),
        hasLength(1),
      );
    }
    final carBatch = writes.batches[batchOf('vehicles/v1')];
    expect(carBatch, containsAll(['vehicles/v1/photos/p1', 'reviews/r1']));
    expect(carBatch.last, 'vehicles/v1');
    expect(writes.batches.last, ['users/u1']);
  });

  test(
    'checklist documents never exceed a batch and go before the parent',
    () async {
      docs.byQuery['bookings:renterId'] = [booking('b1')];
      docs.byList['bookings/b1/checklistEntries'] = [
        for (var i = 0; i < 1000; i++)
          ErasableDoc(path: 'bookings/b1/checklistEntries/c$i', data: {}),
      ];

      await eraser.eraseAll('u1');

      expect(writes.batches.every((batch) => batch.length <= 450), isTrue);
      final parent = batchOf('bookings/b1');
      expect(batchOf('calendarBlocks/b1'), parent);
      expect(
        batchOf('bookings/b1/checklistEntries/c0'),
        lessThanOrEqualTo(parent),
      );
    },
  );

  test('loose documents come after bookings and cars, user last', () async {
    docs.byQuery['bookings:renterId'] = [booking('b1')];
    docs.byQuery['notifications:userId'] = [
      const ErasableDoc(path: 'notifications/n1', data: {}),
    ];
    docs.byQuery['transactions:renterId'] = [
      const ErasableDoc(path: 'transactions/t1', data: {}),
    ];

    await eraser.eraseAll('u1');

    expect(batchOf('notifications/n1'), greaterThan(batchOf('bookings/b1')));
    expect(batchOf('transactions/t1'), greaterThan(batchOf('bookings/b1')));
    expect(flat().last, 'users/u1');
  });
}
