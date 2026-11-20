import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/features/vehicles/domain/entities/availability_overview.dart';
import 'package:veloce/features/vehicles/domain/entities/day_range.dart';
import 'package:veloce/features/vehicles/domain/usecases/set_availability.dart';
import 'package:veloce/features/vehicles/domain/usecases/watch_availability.dart';
import 'package:veloce/features/vehicles/presentation/bloc/availability_bloc.dart';

import '../../domain/builders.dart';

void main() {
  final clock = FixedClock(DateTime(2026, 11, 14));
  final car = aVehicle();
  final bookedDays = [DayRange(DateTime(2026, 12, 1), DateTime(2026, 12, 5))];

  AvailabilityBloc buildBloc(FakeVehicleRepository repository) {
    repository.vehicles['car-1'] = car;
    return AvailabilityBloc(
      watchAvailability: WatchAvailability(repository, clock),
      setAvailability: SetAvailability(repository, clock),
    );
  }

  final loaded = AvailabilityLoaded(
    overview: AvailabilityOverview(vehicle: car, bookedDays: bookedDays),
    from: null,
    to: null,
  );

  FakeVehicleRepository withBooking() => FakeVehicleRepository(
    bookings: [aBooking(status: BookingStatus.confirmed)],
  );

  group('AvailabilityBloc', () {
    blocTest<AvailabilityBloc, AvailabilityState>(
      'start loads the car with its booked days',
      build: () => buildBloc(withBooking()),
      act: (bloc) => bloc.add(const AvailabilityStarted('car-1')),
      expect: () => [const AvailabilityLoading(), loaded],
    );

    blocTest<AvailabilityBloc, AvailabilityState>(
      'range that drops a booked day exposes a problem and cannot be saved',
      build: () => buildBloc(withBooking()),
      act: (bloc) async {
        bloc.add(const AvailabilityStarted('car-1'));
        await Future<void>.delayed(Duration.zero);
        bloc
          ..add(
            AvailabilityRangeChanged(
              DateTime(2026, 12, 3),
              DateTime(2026, 12, 31),
            ),
          )
          ..add(const AvailabilitySaved());
      },
      verify: (bloc) {
        final state = bloc.state as AvailabilityLoaded;
        expect(state.problem, isNotNull);
        expect(state.saving, isFalse);
        expect(state.saved, isFalse);
      },
    );

    blocTest<AvailabilityBloc, AvailabilityState>(
      'valid range is saved',
      build: () => buildBloc(withBooking()),
      act: (bloc) async {
        bloc.add(const AvailabilityStarted('car-1'));
        await Future<void>.delayed(Duration.zero);
        bloc
          ..add(
            AvailabilityRangeChanged(
              DateTime(2026, 11, 20),
              DateTime(2026, 12, 31),
            ),
          )
          ..add(const AvailabilitySaved());
      },
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        final state = bloc.state as AvailabilityLoaded;
        expect(state.saved, isTrue);
        expect(state.edited, isFalse);
        expect(state.notice, isNull);
      },
    );
  });
}
