import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/booking/domain/entities/booking_view.dart';
import 'package:veloce/features/booking/presentation/bloc/decision_bloc.dart';

import '../../support/booking_test_data.dart';

void main() {
  late MockAuthSession session;
  late MockBookingRepository repository;
  late MockApproveBooking approve;
  late MockDeclineBooking decline;

  final pending = bookingView(status: BookingStatus.pending);

  DecisionBloc build() => DecisionBloc(
    bookingId: 'booking-1',
    repository: repository,
    approve: approve,
    decline: decline,
    session: session,
  );

  setUpAll(() => registerFallbackValue(pending));

  setUp(() {
    session = MockAuthSession();
    repository = MockBookingRepository();
    approve = MockApproveBooking();
    decline = MockDeclineBooking();
    when(() => session.role).thenReturn(UserRole.owner);
    when(() => session.currentUserId).thenReturn('owner-1');
  });

  blocTest<DecisionBloc, DecisionState>(
    'only the owner can open the decision screen',
    setUp: () => when(() => session.role).thenReturn(UserRole.renter),
    build: build,
    act: (bloc) => bloc.add(const DecisionStarted()),
    expect: () => [
      const DecisionFailure(
        PermissionFailure('Only the car owner can review requests.'),
      ),
    ],
  );

  blocTest<DecisionBloc, DecisionState>(
    'loads the request and starts with the tick off',
    setUp: () {
      when(() => repository.watchBooking('booking-1'))
          .thenAnswer((_) => Stream.value(Result.success(pending)));
    },
    build: build,
    act: (bloc) => bloc.add(const DecisionStarted()),
    expect: () => [
      const DecisionLoading(),
      isA<DecisionLoaded>()
          .having((state) => state.view, 'view', pending)
          .having((state) => state.reviewed, 'reviewed', isFalse),
    ],
  );

  blocTest<DecisionBloc, DecisionState>(
    'toggles the reviewed tick without calling the use case',
    build: build,
    seed: () => DecisionLoaded(view: pending),
    act: (bloc) => bloc.add(const DecisionReviewToggled(true)),
    expect: () => [
      isA<DecisionLoaded>().having(
        (state) => state.reviewed,
        'reviewed',
        isTrue,
      ),
    ],
    verify: (_) {
      verifyNever(() => approve(any(), reviewed: any(named: 'reviewed')));
    },
  );

  blocTest<DecisionBloc, DecisionState>(
    'approval without the tick reports validation',
    setUp: () {
      when(() => approve('booking-1', reviewed: false)).thenAnswer(
        (_) async => const Result.failure(
          ValidationFailure('Tick "I reviewed their info" first.'),
        ),
      );
    },
    build: build,
    seed: () => DecisionLoaded(view: pending),
    act: (bloc) => bloc.add(const DecisionApproved()),
    expect: () => [
      isA<DecisionLoaded>().having(
        (state) => state.action.status,
        'status',
        DecisionActionStatus.submitting,
      ),
      isA<DecisionLoaded>()
          .having(
            (state) => state.action.status,
            'status',
            DecisionActionStatus.failure,
          )
          .having(
            (state) => state.action.message,
            'message',
            'Tick "I reviewed their info" first.',
          ),
    ],
  );

  blocTest<DecisionBloc, DecisionState>(
    'approval reports success',
    setUp: () {
      when(() => approve('booking-1', reviewed: true))
          .thenAnswer((_) async => const Result.success(null));
    },
    build: build,
    seed: () => DecisionLoaded(view: pending, reviewed: true),
    act: (bloc) => bloc.add(const DecisionApproved()),
    expect: () => [
      isA<DecisionLoaded>().having(
        (state) => state.action.status,
        'status',
        DecisionActionStatus.submitting,
      ),
      isA<DecisionLoaded>().having(
        (state) => state.action.status,
        'status',
        DecisionActionStatus.success,
      ),
    ],
  );

  blocTest<DecisionBloc, DecisionState>(
    'decline passes the reason and reports failure',
    setUp: () {
      when(() => decline('booking-1', reason: 'Not available')).thenAnswer(
        (_) async =>
            const Result.failure(ConflictFailure('This request has expired.')),
      );
    },
    build: build,
    seed: () => DecisionLoaded(view: pending),
    act: (bloc) => bloc.add(const DecisionDeclineSubmitted('Not available')),
    expect: () => [
      isA<DecisionLoaded>().having(
        (state) => state.action.status,
        'status',
        DecisionActionStatus.submitting,
      ),
      isA<DecisionLoaded>()
          .having(
            (state) => state.action.status,
            'status',
            DecisionActionStatus.failure,
          )
          .having(
            (state) => state.action.message,
            'message',
            'This request has expired.',
          ),
    ],
  );

  blocTest<DecisionBloc, DecisionState>(
    'a booking update during approval is kept, not overwritten',
    setUp: () {
      final approved = bookingView(status: BookingStatus.approved);
      final controller = StreamController<Result<BookingView>>();
      addTearDown(controller.close);
      when(() => repository.watchBooking('booking-1'))
          .thenAnswer((_) => controller.stream);
      when(() => approve('booking-1', reviewed: false)).thenAnswer((_) async {
        controller.add(Result.success(approved));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return const Result.success(null);
      });
      controller.add(Result.success(pending));
    },
    build: build,
    act: (bloc) async {
      bloc.add(const DecisionStarted());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      bloc.add(const DecisionApproved());
    },
    wait: const Duration(milliseconds: 50),
    verify: (bloc) {
      final state = bloc.state as DecisionLoaded;
      expect(state.view.booking.status, BookingStatus.approved);
      expect(state.action.status, DecisionActionStatus.success);
    },
  );
}
