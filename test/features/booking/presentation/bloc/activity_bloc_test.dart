import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/booking/presentation/bloc/activity_bloc.dart';

import '../../support/booking_test_data.dart';

void main() {
  late MockAuthSession session;
  late MockBookingRepository repository;
  late MockCancelBooking cancelBooking;
  late MockExpireBookings expireBookings;

  final pending = bookingView(status: BookingStatus.pending);
  final approved = bookingView(status: BookingStatus.approved, id: 'booking-2');
  final confirmed = bookingView(
    status: BookingStatus.confirmed,
    id: 'booking-3',
  );
  final cancelled = bookingView(
    status: BookingStatus.cancelled,
    id: 'booking-4',
  );

  ActivityBloc build() => ActivityBloc(
    repository: repository,
    cancelBooking: cancelBooking,
    expireBookings: expireBookings,
    session: session,
  );

  setUpAll(() => registerFallbackValue(pending));

  setUp(() {
    session = MockAuthSession();
    repository = MockBookingRepository();
    cancelBooking = MockCancelBooking();
    expireBookings = MockExpireBookings();
    when(() => session.role).thenReturn(UserRole.renter);
    when(() => session.currentUserId).thenReturn('renter-1');
    when(() => expireBookings())
        .thenAnswer((_) async => const Result.success(0));
  });

  blocTest<ActivityBloc, ActivityState>(
    'loads and classifies open, active and past bookings',
    setUp: () {
      when(() => repository.watchMyBookings()).thenAnswer(
        (_) => Stream.value(
          Result.success([pending, approved, confirmed, cancelled]),
        ),
      );
    },
    build: build,
    act: (bloc) => bloc.add(const ActivityStarted()),
    expect: () => [
      const ActivityLoading(),
      isA<ActivityLoaded>()
          .having((state) => state.role, 'role', UserRole.renter)
          .having((state) => state.open.length, 'open', 2)
          .having((state) => state.active.length, 'active', 1)
          .having((state) => state.past.length, 'past', 1),
    ],
    verify: (_) {
      verify(() => expireBookings()).called(1);
      verify(() => repository.watchMyBookings()).called(1);
    },
  );

  blocTest<ActivityBloc, ActivityState>(
    'owners get one open group per car',
    setUp: () {
      when(() => session.role).thenReturn(UserRole.owner);
      final otherCar = pending.copyWith(
        booking: pending.booking.copyWith(vehicleId: 'car-2'),
        vehicle: pending.vehicle.copyWith(id: 'car-2'),
      );
      when(() => repository.watchMyBookings())
          .thenAnswer((_) => Stream.value(Result.success([pending, otherCar])));
    },
    build: build,
    act: (bloc) => bloc.add(const ActivityStarted()),
    expect: () => [const ActivityLoading(), isA<ActivityLoaded>()],
    verify: (bloc) {
      final loaded = bloc.state as ActivityLoaded;
      expect(loaded.openGroups, hasLength(2));
    },
  );

  blocTest<ActivityBloc, ActivityState>(
    'an expiry sweep failure is shown',
    setUp: () {
      when(() => expireBookings())
          .thenAnswer((_) async => const Result.failure(NetworkFailure()));
    },
    build: build,
    act: (bloc) => bloc.add(const ActivityStarted()),
    expect: () => [
      const ActivityLoading(),
      const ActivityFailure(NetworkFailure()),
    ],
  );

  blocTest<ActivityBloc, ActivityState>(
    'switches tabs without reloading',
    build: build,
    seed: () =>
        ActivityLoaded(role: UserRole.renter, bookings: [pending, confirmed]),
    act: (bloc) => bloc.add(const ActivityTabChanged(ActivityTab.active)),
    expect: () => [
      isA<ActivityLoaded>().having(
        (state) => state.tab,
        'tab',
        ActivityTab.active,
      ),
    ],
  );

  blocTest<ActivityBloc, ActivityState>(
    'cancelling reports submitting then success',
    setUp: () {
      when(() => cancelBooking(pending, reason: null))
          .thenAnswer((_) async => const Result.success(null));
    },
    build: build,
    seed: () => ActivityLoaded(role: UserRole.renter, bookings: [pending]),
    act: (bloc) => bloc.add(ActivityCancelRequested(pending)),
    expect: () => [
      isA<ActivityLoaded>().having(
        (state) => state.action.status,
        'status',
        ActivityActionStatus.submitting,
      ),
      isA<ActivityLoaded>().having(
        (state) => state.action.status,
        'status',
        ActivityActionStatus.success,
      ),
    ],
  );

  blocTest<ActivityBloc, ActivityState>(
    'cancelling reports the failure message',
    setUp: () {
      when(() => cancelBooking(pending, reason: null)).thenAnswer(
        (_) async => const Result.failure(
          ConflictFailure('This booking can no longer be cancelled.'),
        ),
      );
    },
    build: build,
    seed: () => ActivityLoaded(role: UserRole.renter, bookings: [pending]),
    act: (bloc) => bloc.add(ActivityCancelRequested(pending)),
    expect: () => [
      isA<ActivityLoaded>(),
      isA<ActivityLoaded>()
          .having(
            (state) => state.action.status,
            'status',
            ActivityActionStatus.failure,
          )
          .having(
            (state) => state.action.message,
            'message',
            'This booking can no longer be cancelled.',
          ),
    ],
  );
}
