import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/entities/document_photo.dart';
import 'package:veloce/core/domain/entities/vehicle_document.dart';
import 'package:veloce/core/domain/enums/document_kind.dart';
import 'package:veloce/core/domain/enums/vehicle_status.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/vehicles/domain/entities/document_input.dart';
import 'package:veloce/features/vehicles/domain/usecases/recompute_docs_valid_until.dart';
import 'package:veloce/features/vehicles/domain/usecases/upsert_document.dart';
import 'package:veloce/features/vehicles/domain/usecases/verify_document.dart';

import '../builders.dart';

VehicleDocument _doc(DocumentKind kind, DateTime expiry) => VehicleDocument(
  kind: kind,
  vehicleId: 'car-1',
  number: 'N-1',
  expiry: expiry,
  photoUrl: 'https://files.test/old.jpg',
  verified: true,
);

DocumentInput _input({
  DocumentKind kind = DocumentKind.insurance,
  String plate = 'RAB 123 A',
  DateTime? expiry,
  bool withPhoto = true,
}) {
  return DocumentInput(
    kind: kind,
    number: 'N-2',
    plate: plate,
    expiry: expiry ?? DateTime(2027, 6, 1),
    photo: withPhoto
        ? DocumentPhoto(bytes: Uint8List(1), extension: 'jpg')
        : null,
  );
}

void main() {
  final clock = FixedClock(DateTime(2026, 11, 14));

  late FakeVehicleRepository repository;
  late FakeMediaStorage storage;

  UpsertDocument build({bool verifies = true}) => UpsertDocument(
    repository,
    storage,
    VerifyDocument(FakeVerificationProvider(succeeds: verifies)),
    const RecomputeDocsValidUntil(),
    clock,
  );

  setUp(() {
    repository = FakeVehicleRepository();
    storage = FakeMediaStorage();
  });

  final expiredInsurance = _doc(DocumentKind.insurance, DateTime(2026, 11, 1));
  final medical = _doc(DocumentKind.medical, DateTime(2027, 9, 1));

  test(
    'replacing an expired insurance on a paused car keeps it paused',
    () async {
      final result = await build()(
        vehicle: aVehicle(docsValidUntil: DateTime(2026, 11, 1)),
        current: [expiredInsurance, medical],
        input: _input(),
      );

      expect(result, isA<Success<void>>());
      expect(repository.upserted.single.expiry, DateTime(2027, 6, 1));
      expect(repository.upserted.single.verified, isTrue);
      expect(repository.statuses['car-1'], VehicleStatus.paused);
      expect(storage.uploaded, hasLength(1));
    },
  );

  test('a published car stays published when documents are valid', () async {
    await build()(
      vehicle: aVehicle(status: VehicleStatus.published),
      current: [medical],
      input: _input(),
    );

    expect(repository.statuses['car-1'], VehicleStatus.published);
  });

  test('another expired required paper pauses a published car', () async {
    await build()(
      vehicle: aVehicle(status: VehicleStatus.published),
      current: [_doc(DocumentKind.medical, DateTime(2026, 10, 1))],
      input: _input(),
    );

    expect(repository.statuses['car-1'], VehicleStatus.paused);
  });

  test('adding the yellow paper keeps the status', () async {
    final result = await build()(
      vehicle: aVehicle(status: VehicleStatus.published),
      current: [_doc(DocumentKind.insurance, DateTime(2027, 2, 1)), medical],
      input: _input(kind: DocumentKind.yellowPaper),
    );

    expect(result, isA<Success<void>>());
    expect(repository.statuses['car-1'], VehicleStatus.published);
  });

  test('plate that differs from the car fails and writes nothing', () async {
    final result = await build()(
      vehicle: aVehicle(),
      current: [medical],
      input: _input(plate: 'RAZ 999 Z'),
    );

    expect(result, isA<Failure<void>>());
    expect(repository.upserted, isEmpty);
    expect(storage.uploaded, isEmpty);
  });

  test('expiry in the past fails', () async {
    final result = await build()(
      vehicle: aVehicle(),
      current: [medical],
      input: _input(expiry: DateTime(2026, 11, 1)),
    );

    expect(result, isA<Failure<void>>());
    expect(repository.upserted, isEmpty);
  });

  test('a new document without a photo fails', () async {
    final result = await build()(
      vehicle: aVehicle(),
      current: [medical],
      input: _input(withPhoto: false),
    );

    expect(result, isA<Failure<void>>());
  });

  test('replacing without a new photo keeps the existing photo', () async {
    await build()(
      vehicle: aVehicle(),
      current: [expiredInsurance, medical],
      input: _input(withPhoto: false),
    );

    expect(repository.upserted.single.photoUrl, 'https://files.test/old.jpg');
    expect(storage.uploaded, isEmpty);
  });

  test('failed verification stops before the upload', () async {
    final result = await build(verifies: false)(
      vehicle: aVehicle(),
      current: [medical],
      input: _input(),
    );

    expect(result, isA<Failure<void>>());
    expect(storage.uploaded, isEmpty);
    expect(repository.upserted, isEmpty);
  });

  test('failed upload writes nothing', () async {
    storage = FakeMediaStorage(failOnUpload: 0);

    final result = await build()(
      vehicle: aVehicle(),
      current: [medical],
      input: _input(),
    );

    expect(result, isA<Failure<void>>());
    expect(repository.upserted, isEmpty);
  });
}
