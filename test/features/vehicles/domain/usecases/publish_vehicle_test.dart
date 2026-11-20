import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/enums/document_kind.dart';
import 'package:veloce/core/error/result.dart';
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
