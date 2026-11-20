import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/entities/vehicle_photo.dart';
import 'package:veloce/core/domain/enums/vehicle_status.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
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
