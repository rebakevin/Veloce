import 'package:bloc_test/bloc_test.dart';
import 'package:veloce/core/domain/entities/vehicle.dart';
import 'package:veloce/core/domain/enums/vehicle_status.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/vehicles/domain/usecases/watch_owner_vehicles.dart';
import 'package:veloce/features/vehicles/presentation/bloc/car_count_cubit.dart';

import '../../domain/builders.dart';

void main() {
  CarCountCubit buildCubit(Stream<Result<List<Vehicle>>> stream) {
    return CarCountCubit(
      watchVehicles: WatchOwnerVehicles(
        FakeVehicleRepository(vehicleStream: stream),
        const FakeAuthSession('owner-1'),
      ),
    );
  }

  blocTest<CarCountCubit, CarCountState>(
    'published and paused cars are counted separately',
    build: () => buildCubit(
      Stream.value(
        Result.success([
          aVehicle(status: VehicleStatus.published),
          aVehicle(status: VehicleStatus.published),
          aVehicle(),
        ]),
      ),
    ),
    expect: () => [const CarCountLoaded(published: 2, paused: 1)],
  );

  blocTest<CarCountCubit, CarCountState>(
    'no cars counts zero',
    build: () =>
        buildCubit(Stream.value(const Result<List<Vehicle>>.success([]))),
    expect: () => [const CarCountLoaded(published: 0, paused: 0)],
  );

  blocTest<CarCountCubit, CarCountState>(
    'stream failure emits failure with the message',
    build: () => buildCubit(
      Stream.value(const Result<List<Vehicle>>.failure(NetworkFailure())),
    ),
    expect: () => [
      const CarCountFailure(
        'No connection. Check your internet and try again.',
      ),
    ],
  );
}
