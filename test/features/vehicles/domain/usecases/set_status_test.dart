import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/enums/vehicle_status.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/vehicles/domain/usecases/set_status.dart';

import '../builders.dart';

void main() {
  final clock = FixedClock(DateTime(2026, 11, 14));

  group('SetStatus', () {
    test('resume with expired documents fails and changes nothing', () async {
      final repository = FakeVehicleRepository();
      final vehicle = aVehicle(docsValidUntil: DateTime(2026, 11, 1));

      final result = await SetStatus(repository, clock)(
        vehicle,
        VehicleStatus.published,
      );

      expect(result, isA<Failure<void>>());
      expect(repository.statuses, isEmpty);
    });

    test('resume with no document date fails', () async {
      final repository = FakeVehicleRepository();

      final result = await SetStatus(repository, clock)(
        aVehicle(),
        VehicleStatus.published,
      );

      expect(result, isA<Failure<void>>());
    });

    test('resume with valid documents publishes the car', () async {
      final repository = FakeVehicleRepository();
      final vehicle = aVehicle(docsValidUntil: DateTime(2027, 1, 1));

      final result = await SetStatus(repository, clock)(
        vehicle,
        VehicleStatus.published,
      );

      expect(result, isA<Success<void>>());
      expect(repository.statuses['car-1'], VehicleStatus.published);
    });

    test('pause works even with expired documents', () async {
      final repository = FakeVehicleRepository();
      final vehicle = aVehicle(
        status: VehicleStatus.published,
        docsValidUntil: DateTime(2026, 11, 1),
      );

      final result = await SetStatus(repository, clock)(
        vehicle,
        VehicleStatus.paused,
      );

      expect(result, isA<Success<void>>());
      expect(repository.statuses['car-1'], VehicleStatus.paused);
    });
  });
}
