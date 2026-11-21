import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/entities/document_photo.dart';
import 'package:veloce/core/domain/enums/document_kind.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/vehicles/domain/entities/rules_pdf.dart';
import 'package:veloce/features/vehicles/domain/usecases/publish_vehicle.dart';

import '../builders.dart';

void main() {
  final clock = FixedClock(DateTime(2026, 11, 14));

  PublishVehicle build(
    FakeVehicleRepository repository,
    FakeMediaStorage storage, {
    String? userId = 'owner-1',
  }) {
    return PublishVehicle(repository, storage, FakeAuthSession(userId), clock);
  }

  group('PublishVehicle', () {
    test('a complete draft publishes the car and uploads every file', () async {
      final repository = FakeVehicleRepository();
      final storage = FakeMediaStorage();

      final result = await build(repository, storage)(aPublishableDraft());

      expect(result, isA<Success<String>>());
      expect(storage.uploaded, hasLength(5));
      expect(repository.published.single.vehicle.ownerId, 'owner-1');
    });

    test('a chosen video is uploaded and its url saved on the car', () async {
      final repository = FakeVehicleRepository();
      final storage = FakeMediaStorage();
      final draft = aPublishableDraft().copyWith(
        video: DocumentPhoto(bytes: Uint8List(1), extension: 'mp4'),
      );

      await build(repository, storage)(draft);

      expect(repository.published.single.vehicle.videoUrl, endsWith('.mp4'));
      expect(storage.uploaded, hasLength(6));
    });

    test('a chosen rules PDF is uploaded and its url saved', () async {
      final repository = FakeVehicleRepository();
      final storage = FakeMediaStorage();
      final draft = aPublishableDraft().copyWith(
        rulesPdf: RulesPdf(bytes: Uint8List(1), name: 'rules.pdf'),
      );

      await build(repository, storage)(draft);

      expect(
        repository.published.single.vehicle.rulesFileUrl,
        endsWith('.pdf'),
      );
    });

    test('without a PDF the car has no rules file', () async {
      final repository = FakeVehicleRepository();

      await build(repository, FakeMediaStorage())(aPublishableDraft());

      expect(repository.published.single.vehicle.rulesFileUrl, isNull);
    });

    test('a failed rules PDF upload cleans up earlier uploads', () async {
      final repository = FakeVehicleRepository();
      final storage = FakeMediaStorage(failOnUpload: 3);
      final draft = aPublishableDraft().copyWith(
        rulesPdf: RulesPdf(bytes: Uint8List(1), name: 'rules.pdf'),
      );

      final result = await build(repository, storage)(draft);

      expect(result, isA<Failure<String>>());
      expect(storage.deleted, storage.uploaded);
      expect(repository.published, isEmpty);
    });

    test('extras typed in the rules step are saved', () async {
      final repository = FakeVehicleRepository();
      final draft = aPublishableDraft().copyWith(extras: ['Child seat']);

      await build(repository, FakeMediaStorage())(draft);

      expect(repository.published.single.vehicle.extras, ['Child seat']);
    });

    test('docsValidUntil is the earlier of insurance and medical', () async {
      final repository = FakeVehicleRepository();
      final draft = aWizardDraft().copyWith(
        documents: {
          DocumentKind.insurance: aDraftDocument(expiry: DateTime(2098, 6, 1)),
          DocumentKind.medical: aDraftDocument(expiry: DateTime(2099, 1, 1)),
        },
      );

      await build(repository, FakeMediaStorage())(draft);

      expect(
        repository.published.single.vehicle.docsValidUntil,
        DateTime(2098, 6, 1),
      );
    });

    test('the chosen main photo is flagged as primary', () async {
      final repository = FakeVehicleRepository();
      final draft = aPublishableDraft().copyWith(primaryIndex: 1);

      await build(repository, FakeMediaStorage())(draft);

      final flags = repository.published.single.photos.map((p) => p.isPrimary);
      expect(flags.toList(), [false, true, false]);
    });

    test('missing documents fail without uploading anything', () async {
      final storage = FakeMediaStorage();

      final result = await build(FakeVehicleRepository(), storage)(
        aWizardDraft(),
      );

      expect(result, isA<Failure<String>>());
      expect(storage.uploaded, isEmpty);
    });

    test('a signed out owner fails', () async {
      final result = await build(
        FakeVehicleRepository(),
        FakeMediaStorage(),
        userId: null,
      )(aPublishableDraft());

      expect(result, isA<Failure<String>>());
    });

    test('an upload failure removes the files already uploaded', () async {
      final storage = FakeMediaStorage(failOnUpload: 2);

      final result = await build(FakeVehicleRepository(), storage)(
        aPublishableDraft(),
      );

      expect(result, isA<Failure<String>>());
      expect(storage.deleted, storage.uploaded);
    });

    test('a failed save removes every uploaded file', () async {
      final storage = FakeMediaStorage();
      final repository = FakeVehicleRepository(publishFails: true);

      final result = await build(repository, storage)(aPublishableDraft());

      expect(result, isA<Failure<String>>());
      expect(storage.deleted, hasLength(5));
    });
  });
}
