import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/theme/app_theme.dart';
import 'package:veloce/features/vehicles/domain/usecases/set_availability.dart';
import 'package:veloce/features/vehicles/domain/usecases/watch_availability.dart';
import 'package:veloce/features/vehicles/presentation/bloc/availability_bloc.dart';
import 'package:veloce/features/vehicles/presentation/pages/availability_page.dart';

import '../../domain/builders.dart';

void main() {
  tearDown(() => GetIt.I.reset());

  testWidgets('shows the booked days as locked and Save starts disabled', (
    tester,
  ) async {
    final clock = FixedClock(DateTime(2026, 11, 14));
    GetIt.I.registerSingleton<Clock>(clock);
    final repository = FakeVehicleRepository(
      bookings: [aBooking(status: BookingStatus.confirmed)],
    )..vehicles['car-1'] = aVehicle();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider(
          create: (_) => AvailabilityBloc(
            watchAvailability: WatchAvailability(repository, clock),
            setAvailability: SetAvailability(repository, clock),
          )..add(const AvailabilityStarted('car-1')),
          child: const AvailabilityPage(vehicleId: 'car-1'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('1 Dec 2026 to 5 Dec 2026'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    final save = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(save.onPressed, isNull);
  });
}
