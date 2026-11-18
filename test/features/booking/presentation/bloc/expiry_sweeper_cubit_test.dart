import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/booking/presentation/bloc/expiry_sweeper_cubit.dart';

import '../../support/booking_test_data.dart';

void main() {
  late MockExpireBookings expireBookings;
  late MockAuthSession session;
  late Completer<Result<int>> completer;

  ExpirySweeperCubit build() =>
      ExpirySweeperCubit(expireBookings: expireBookings, session: session);

  setUp(() {
    expireBookings = MockExpireBookings();
    session = MockAuthSession();
    when(() => session.currentUserId).thenReturn('renter-1');
    when(() => session.role).thenReturn(UserRole.renter);
  });

  blocTest<ExpirySweeperCubit, ExpirySweeperState>(
    'does nothing when signed out',
    setUp: () => when(() => session.currentUserId).thenReturn(null),
    build: build,
    act: (cubit) => cubit.sweep(),
    expect: () => [const ExpirySweeperDone(0)],
    verify: (_) => verifyNever(() => expireBookings()),
  );

  blocTest<ExpirySweeperCubit, ExpirySweeperState>(
    'reports how many bookings were written',
    setUp: () {
      when(() => expireBookings())
          .thenAnswer((_) async => const Result.success(2));
    },
    build: build,
    act: (cubit) => cubit.sweep(),
    expect: () => [const ExpirySweeperRunning(), const ExpirySweeperDone(2)],
    verify: (_) => verify(() => expireBookings()).called(1),
  );

  blocTest<ExpirySweeperCubit, ExpirySweeperState>(
    'surfaces a failed sweep',
    setUp: () {
      when(() => expireBookings())
          .thenAnswer((_) async => const Result.failure(NetworkFailure()));
    },
    build: build,
    act: (cubit) => cubit.sweep(),
    expect: () => [
      const ExpirySweeperRunning(),
      const ExpirySweeperFailure(NetworkFailure()),
    ],
  );

  blocTest<ExpirySweeperCubit, ExpirySweeperState>(
    'ignores a second sweep while one is running',
    setUp: () {
      completer = Completer<Result<int>>();
      when(() => expireBookings()).thenAnswer((_) => completer.future);
      addTearDown(() {
        if (!completer.isCompleted) completer.complete(const Result.success(0));
      });
    },
    build: build,
    act: (cubit) async {
      final first = cubit.sweep();
      await cubit.sweep();
      await Future<void>.delayed(Duration.zero);
      completer.complete(const Result.success(1));
      await first;
    },
    expect: () => [const ExpirySweeperRunning(), const ExpirySweeperDone(1)],
    verify: (_) => verify(() => expireBookings()).called(1),
  );
}
