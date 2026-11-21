import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/entities/document_photo.dart';
import 'package:veloce/core/domain/entities/vehicle_photo.dart';
import 'package:veloce/core/domain/enums/vehicle_status.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/vehicles/domain/entities/rules_pdf.dart';
import 'package:veloce/features/vehicles/domain/entities/wizard_draft.dart';
import 'package:veloce/features/vehicles/domain/usecases/update_vehicle.dart';

import '../builders.dart';

VehiclePhoto _photo(int order) => VehiclePhoto(
  id: 'p$order',
  vehicleId: 'car-1',
  url: 'https://files.test/old$order.jpg',
  order: order,
  isPrimary: order == 0,
);

void main() {
  FakeVehicleRepository seeded() {
    final repository = FakeVehicleRepository();
    repository.vehicles['car-1'] = aVehicle(
      status: VehicleStatus.published,
      docsValidUntil: DateTime(2027),
    );
    repository.photos['car-1'] = [_photo(0), _photo(1), _photo(2)];
    return repository;
  }

  WizardDraft draft({int newPhotos = 0, int kept = 3}) {
    return aWizardDraft().copyWith(
      vehicleId: 'car-1',
      keptPhotos: [for (var i = 0; i < kept; i++) _photo(i)],
      photos: somePhotos(newPhotos),
      dailyPrice: 65000,
      longRates: const [],
    );
  }

  UpdateVehicle build(
    FakeVehicleRepository repository,
    FakeMediaStorage storage, {
    String? userId = 'owner-1',
  }) => UpdateVehicle(repository, storage, FakeAuthSession(userId));

  group('UpdateVehicle', () {
    test('saves the new price and keeps status and docsValidUntil', () async {
      final repository = seeded();

      final result = await build(repository, FakeMediaStorage())(draft());

      expect(result, isA<Success<void>>());
      final saved = repository.vehicles['car-1']!;
      expect(saved.dailyPrice, 65000);
      expect(saved.status, VehicleStatus.published);
      expect(saved.docsValidUntil, DateTime(2027));
    });

    test('a reordered kept photo list is saved in the new order', () async {
      final repository = seeded();
      final reordered = draft().movePhoto(2, -1).movePhoto(1, -1);

      await build(repository, FakeMediaStorage())(reordered);

      expect(repository.photos['car-1']!.map((p) => p.url), [
        'https://files.test/old2.jpg',
        'https://files.test/old0.jpg',
        'https://files.test/old1.jpg',
      ]);
    });

    test('a new video is uploaded and its url saved', () async {
      final repository = seeded();
      final storage = FakeMediaStorage();
      final withVideo = draft().copyWith(
        video: DocumentPhoto(bytes: Uint8List(1), extension: 'mp4'),
      );

      await build(repository, storage)(withVideo);

      expect(repository.vehicles['car-1']!.videoUrl, endsWith('.mp4'));
      expect(repository.photos['car-1'], hasLength(3));
    });

    test('an existing video is kept when the draft still carries it', () async {
      final repository = seeded();
      repository.vehicles['car-1'] = aVehicle(videoUrl: 'https://f.test/v.mp4');
      final kept = draft().copyWith(existingVideoUrl: 'https://f.test/v.mp4');

      await build(repository, FakeMediaStorage())(kept);

      expect(repository.vehicles['car-1']!.videoUrl, 'https://f.test/v.mp4');
    });

    test(
      'removing the existing video clears it and deletes the file',
      () async {
        final repository = seeded();
        repository.vehicles['car-1'] = aVehicle(
          videoUrl: 'https://f.test/v.mp4',
        );
        final storage = FakeMediaStorage();

        await build(repository, storage)(draft());

        expect(repository.vehicles['car-1']!.videoUrl, isNull);
        expect(storage.deleted, contains('https://f.test/v.mp4'));
      },
    );

    test('new photos are uploaded and appended after kept ones', () async {
      final repository = seeded();
      final storage = FakeMediaStorage();

      await build(repository, storage)(draft(newPhotos: 1));

      expect(storage.uploaded, hasLength(1));
      final urls = repository.photos['car-1']!.map((p) => p.url).toList();
      expect(urls.last, storage.uploaded.single);
      expect(urls, hasLength(4));
    });

    test('removed photos are deleted after the save', () async {
      final repository = seeded();
      final storage = FakeMediaStorage();

      await build(repository, storage)(draft(newPhotos: 1, kept: 2));

      expect(storage.deleted, ['https://files.test/old2.jpg']);
    });

    test('a failed upload cleans up and does not save', () async {
      final repository = seeded();
      final storage = FakeMediaStorage(failOnUpload: 1);

      final result = await build(repository, storage)(draft(newPhotos: 2));

      expect(result, isA<Failure<void>>());
      expect(storage.deleted, storage.uploaded);
      expect(repository.vehicles['car-1']!.dailyPrice, 50000);
    });

    test('a new rules PDF is uploaded and saved on the car', () async {
      final repository = seeded();

      await build(repository, FakeMediaStorage())(
        draft().copyWith(
          rulesPdf: RulesPdf(bytes: Uint8List(1), name: 'rules.pdf'),
        ),
      );

      expect(repository.vehicles['car-1']!.rulesFileUrl, endsWith('.pdf'));
    });

    test('removing the rules PDF clears it and deletes the file', () async {
      final repository = seeded();
      repository.vehicles['car-1'] = repository.vehicles['car-1']!.copyWith(
        rulesFileUrl: 'https://files.test/rules.pdf',
      );
      final storage = FakeMediaStorage();

      await build(repository, storage)(draft());

      expect(repository.vehicles['car-1']!.rulesFileUrl, isNull);
      expect(storage.deleted, contains('https://files.test/rules.pdf'));
    });

    test('a kept rules PDF stays and is not deleted', () async {
      final repository = seeded();
      repository.vehicles['car-1'] = repository.vehicles['car-1']!.copyWith(
        rulesFileUrl: 'https://files.test/rules.pdf',
      );
      final storage = FakeMediaStorage();

      await build(repository, storage)(
        draft().copyWith(existingRulesUrl: 'https://files.test/rules.pdf'),
      );

      expect(
        repository.vehicles['car-1']!.rulesFileUrl,
        'https://files.test/rules.pdf',
      );
      expect(storage.deleted, isNot(contains('https://files.test/rules.pdf')));
    });

    test('a failed rules PDF upload cleans up and does not save', () async {
      final repository = seeded();
      final storage = FakeMediaStorage(failOnUpload: 1);

      final result = await build(repository, storage)(
        draft(newPhotos: 1).copyWith(
          rulesPdf: RulesPdf(bytes: Uint8List(1), name: 'rules.pdf'),
        ),
      );

      expect(result, isA<Failure<void>>());
      expect(storage.deleted, storage.uploaded);
    });

    test('an invalid draft is rejected before any upload', () async {
      final storage = FakeMediaStorage();

      final result = await build(seeded(), storage)(
        draft(newPhotos: 1).copyWith(make: ' '),
      );

      expect((result as Failure<void>).failure, isA<ValidationFailure>());
      expect(storage.uploaded, isEmpty);
    });

    test('another owner cannot edit the car', () async {
      final result = await build(
        seeded(),
        FakeMediaStorage(),
        userId: 'owner-2',
      )(draft());

      expect((result as Failure<void>).failure, isA<PermissionFailure>());
    });

    test('a signed-out user is rejected', () async {
      final result = await build(seeded(), FakeMediaStorage(), userId: null)(
        draft(),
      );

      expect(result, isA<Failure<void>>());
    });

    test('a missing car reports not found', () async {
      final result = await build(FakeVehicleRepository(), FakeMediaStorage())(
        draft(),
      );

      expect((result as Failure<void>).failure, isA<NotFoundFailure>());
    });
  });
}
