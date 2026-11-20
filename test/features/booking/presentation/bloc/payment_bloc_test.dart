import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/domain/services/momo_gateway.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/booking/presentation/bloc/payment_bloc.dart';

import '../../support/booking_test_data.dart';

void main() {
  late MockAuthSession session;
  late MockBookingRepository repository;
  late MockPayBooking pay;

  final approved = bookingView(status: BookingStatus.approved);

  PaymentBloc build() => PaymentBloc(
    bookingId: 'booking-1',
    repository: repository,
    pay: pay,
    session: session,
  );

  setUpAll(() => registerFallbackValue(approved));

  setUp(() {
    session = MockAuthSession();
    repository = MockBookingRepository();
    pay = MockPayBooking();
    when(() => session.role).thenReturn(UserRole.renter);
    when(() => session.currentUserId).thenReturn('renter-1');
  });

  blocTest<PaymentBloc, PaymentState>(
    'only the renter can open the payment screen',
    setUp: () => when(() => session.role).thenReturn(UserRole.owner),
    build: build,
    act: (bloc) => bloc.add(const PaymentStarted()),
    expect: () => [
      const PaymentFailure(
        PermissionFailure('Only the renter can pay for this booking.'),
      ),
    ],
  );

  blocTest<PaymentBloc, PaymentState>(
    'loads the approved booking',
    setUp: () {
      when(() => repository.watchBooking('booking-1'))
          .thenAnswer((_) => Stream.value(Result.success(approved)));
    },
    build: build,
    act: (bloc) => bloc.add(const PaymentStarted()),
    expect: () => [
      const PaymentLoading(),
      isA<PaymentLoaded>().having((state) => state.view, 'view', approved),
    ],
  );

  blocTest<PaymentBloc, PaymentState>(
    'a successful charge keeps the reference',
    setUp: () {
      when(() => pay(approved, momoNumber: '788123456')).thenAnswer(
        (_) async => const Result.success(MomoReceipt(reference: 'MOMO-99')),
      );
    },
    build: build,
    seed: () => PaymentLoaded(view: approved),
    act: (bloc) => bloc.add(const PaymentSubmitted('788123456')),
    expect: () => [
      isA<PaymentLoaded>().having(
        (state) => state.action.status,
        'status',
        PaymentActionStatus.processing,
      ),
      isA<PaymentLoaded>()
          .having(
            (state) => state.action.status,
            'status',
            PaymentActionStatus.success,
          )
          .having((state) => state.action.reference, 'reference', 'MOMO-99'),
    ],
  );

  blocTest<PaymentBloc, PaymentState>(
    'a failed charge can be retried with the same number',
    setUp: () {
      var calls = 0;
      when(() => pay(approved, momoNumber: '788123456')).thenAnswer((_) async {
        calls++;
        return calls == 1
            ? const Result.failure(
                ConflictFailure('The payment was not approved.'),
              )
            : const Result.success(MomoReceipt(reference: 'MOMO-100'));
      });
    },
    build: build,
    seed: () => PaymentLoaded(view: approved),
    act: (bloc) async {
      bloc.add(const PaymentSubmitted('788123456'));
      await bloc.stream.firstWhere(
        (state) =>
            state is PaymentLoaded &&
            state.action.status == PaymentActionStatus.failure,
      );
      bloc.add(const PaymentRetried());
    },
    expect: () => [
      isA<PaymentLoaded>().having(
        (state) => state.action.status,
        'status',
        PaymentActionStatus.processing,
      ),
      isA<PaymentLoaded>()
          .having(
            (state) => state.action.status,
            'status',
            PaymentActionStatus.failure,
          )
          .having(
            (state) => state.action.message,
            'message',
            'The payment was not approved.',
          ),
      isA<PaymentLoaded>().having(
        (state) => state.action.status,
        'status',
        PaymentActionStatus.processing,
      ),
      isA<PaymentLoaded>()
          .having(
            (state) => state.action.status,
            'status',
            PaymentActionStatus.success,
          )
          .having((state) => state.action.reference, 'reference', 'MOMO-100'),
    ],
    verify: (_) =>
        verify(() => pay(approved, momoNumber: '788123456')).called(2),
  );

  blocTest<PaymentBloc, PaymentState>(
    'retry before any number does nothing',
    build: build,
    seed: () => PaymentLoaded(view: approved),
    act: (bloc) => bloc.add(const PaymentRetried()),
    expect: () => [],
    verify: (_) =>
        verifyNever(() => pay(any(), momoNumber: any(named: 'momoNumber'))),
  );
}
