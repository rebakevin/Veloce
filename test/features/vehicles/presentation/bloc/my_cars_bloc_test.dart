import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/entities/vehicle.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/domain/enums/vehicle_status.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/vehicles/domain/usecases/find_next_rentals.dart';
import 'package:veloce/features/vehicles/domain/usecases/remove_vehicle.dart';
import 'package:veloce/features/vehicles/domain/usecases/set_status.dart';
import 'package:veloce/features/vehicles/domain/usecases/watch_owner_vehicles.dart';
import 'package:veloce/features/vehicles/presentation/bloc/my_cars_bloc.dart';

import '../../domain/builders.dart';

void main() {
  final clock = FixedClock(DateTime(2026, 11, 14));

  MyCarsBloc buildBloc(FakeVehicleRepository repository) {
    return MyCarsBloc(
      watchVehicles: WatchOwnerVehicles(
        repository,
        const FakeAuthSession('owner-1'),
      ),
      setStatus: SetStatus(repository, clock),
      removeVehicle: RemoveVehicle(repository, clock),
      findNextRentals: FindNextRentals(repository, clock),
    );
  }

  group('MyCarsBloc loading', () {
    blocTest<MyCarsBloc, MyCarsState>(
      'cars arrive emits loaded with the cars',
      build: () => buildBloc(
        FakeVehicleRepository(
          vehicleStream: Stream.value(Result.success([aVehicle()])),
        ),
      ),
      act: (bloc) => bloc.add(const MyCarsStarted()),
      expect: () => [
        const MyCarsLoading(),
        MyCarsLoaded([aVehicle()]),
      ],
    );

    blocTest<MyCarsBloc, MyCarsState>(
      'an open booking shows as the next rental of the car',
      build: () => buildBloc(
        FakeVehicleRepository(
          vehicleStream: Stream.value(Result.success([aVehicle()])),
          bookings: [aBooking(status: BookingStatus.confirmed)],
        ),
      ),
      act: (bloc) => bloc.add(const MyCarsStarted()),
      expect: () => [
        const MyCarsLoading(),
        isA<MyCarsLoaded>().having((s) => s.nextRentals.keys, 'next rentals', [
          'car-1',
        ]),
      ],
    );

    blocTest<MyCarsBloc, MyCarsState>(
      'no cars emits empty',
      build: () => buildBloc(
        FakeVehicleRepository(
          vehicleStream: Stream.value(const Result<List<Vehicle>>.success([])),
        ),
      ),
      act: (bloc) => bloc.add(const MyCarsStarted()),
      expect: () => [const MyCarsLoading(), const MyCarsEmpty()],
    );

    blocTest<MyCarsBloc, MyCarsState>(
      'stream failure emits failure with the message',
      build: () => buildBloc(
        FakeVehicleRepository(
          vehicleStream: Stream.value(
            const Result<List<Vehicle>>.failure(NetworkFailure()),
          ),
        ),
      ),
      act: (bloc) => bloc.add(const MyCarsStarted()),
      expect: () => [
        const MyCarsLoading(),
        const MyCarsFailure(
          'No connection. Check your internet and try again.',
        ),
      ],
    );
  });

  group('MyCarsBloc actions', () {
    final paused = aVehicle(docsValidUntil: DateTime(2026, 11, 1));

    blocTest<MyCarsBloc, MyCarsState>(
      'resume with expired documents shows a notice',
      build: () => buildBloc(FakeVehicleRepository()),
      seed: () => MyCarsLoaded([paused]),
      act: (bloc) => bloc.add(MyCarsStatusToggled(paused)),
      expect: () => [
        isA<MyCarsLoaded>().having((s) => s.notice, 'notice', isNotNull),
      ],
    );

    blocTest<MyCarsBloc, MyCarsState>(
      'pause changes the status without a notice',
      build: () => buildBloc(FakeVehicleRepository()),
      seed: () => MyCarsLoaded([aVehicle(status: VehicleStatus.published)]),
      act: (bloc) => bloc.add(
        MyCarsStatusToggled(aVehicle(status: VehicleStatus.published)),
      ),
      expect: () => <MyCarsState>[],
    );

    blocTest<MyCarsBloc, MyCarsState>(
      'remove with an open booking shows a notice and removes nothing',
      build: () => buildBloc(
        FakeVehicleRepository(
          bookings: [aBooking(status: BookingStatus.active)],
        ),
      ),
      seed: () => MyCarsLoaded([aVehicle()]),
      act: (bloc) => bloc.add(const MyCarsRemoveRequested('car-1')),
      expect: () => [
        isA<MyCarsLoaded>().having((s) => s.notice, 'notice', isNotNull),
      ],
    );

    blocTest<MyCarsBloc, MyCarsState>(
      'remove with no open bookings emits nothing and the list follows the stream',
      build: () => buildBloc(FakeVehicleRepository()),
      seed: () => MyCarsLoaded([aVehicle()]),
      act: (bloc) => bloc.add(const MyCarsRemoveRequested('car-1')),
      expect: () => <MyCarsState>[],
    );

    blocTest<MyCarsBloc, MyCarsState>(
      'clearing the notice removes it from the state',
      build: () => buildBloc(FakeVehicleRepository()),
      seed: () => MyCarsLoaded([aVehicle()], notice: 'Something happened.'),
      act: (bloc) => bloc.add(const MyCarsNoticeCleared()),
      expect: () => [
        MyCarsLoaded([aVehicle()]),
      ],
    );
  });
}
