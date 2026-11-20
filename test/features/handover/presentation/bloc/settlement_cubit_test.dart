import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/handover/presentation/bloc/settlement_cubit.dart';
import 'package:veloce/features/handover/presentation/bloc/settlement_state.dart';

import '../../../../support/builders.dart';
import 'handover_fakes.dart';

void main() {
  late MockHandoverRepository repository;

  setUp(() => repository = MockHandoverRepository());

  SettlementCubit createCubit() =>
      SettlementCubit(bookingId: 'booking-1', repository: repository);

  blocTest<SettlementCubit, SettlementState>(
    'owner confirms no issues',
    build: () {
      when(
        () => repository.markNoIssue(
          bookingId: any(named: 'bookingId'),
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async => Result.success(aBooking()));
      return createCubit();
    },
    act: (cubit) => cubit.markNoIssue(userId: 'owner-1'),
    expect: () => [
      const SettlementState(status: SettlementStatus.loading),
      const SettlementState(),
    ],
    verify: (_) => verify(
      () => repository.markNoIssue(bookingId: 'booking-1', userId: 'owner-1'),
    ).called(1),
  );

  blocTest<SettlementCubit, SettlementState>(
    'renter acknowledges and receives the refund',
    build: () {
      when(
        () => repository.acknowledgeNoIssue(
          bookingId: any(named: 'bookingId'),
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async => Result.success(aBooking()));
      return createCubit();
    },
    act: (cubit) => cubit.acknowledgeNoIssue(userId: 'renter-1'),
    expect: () => [
      const SettlementState(status: SettlementStatus.loading),
      const SettlementState(),
    ],
    verify: (_) => verify(
      () => repository.acknowledgeNoIssue(
        bookingId: 'booking-1',
        userId: 'renter-1',
      ),
    ).called(1),
  );

  blocTest<SettlementCubit, SettlementState>(
    'a failure is shown as a message',
    build: () {
      when(
        () => repository.markNoIssue(
          bookingId: any(named: 'bookingId'),
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async => const Result.failure(PermissionFailure()));
      return createCubit();
    },
    act: (cubit) => cubit.markNoIssue(userId: 'owner-1'),
    expect: () => [
      const SettlementState(status: SettlementStatus.loading),
      const SettlementState(
        status: SettlementStatus.failure,
        message: 'This changed while you were working. Please refresh.',
      ),
    ],
  );

  blocTest<SettlementCubit, SettlementState>(
    'an unexpected exception becomes a generic message',
    build: () {
      when(
        () => repository.markNoIssue(
          bookingId: any(named: 'bookingId'),
          userId: any(named: 'userId'),
        ),
      ).thenThrow(StateError('boom'));
      return createCubit();
    },
    act: (cubit) => cubit.markNoIssue(userId: 'owner-1'),
    expect: () => [
      const SettlementState(status: SettlementStatus.loading),
      SettlementState(
        status: SettlementStatus.failure,
        message: const UnknownFailure().message,
      ),
    ],
  );
}
