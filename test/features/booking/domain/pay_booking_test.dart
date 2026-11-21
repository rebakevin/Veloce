import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/domain/services/momo_gateway.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/auth/auth.dart';
import 'package:veloce/features/booking/domain/usecases/pay_booking.dart';

import '../../../support/builders.dart';
import '../support/booking_test_data.dart';

class _FixedClock implements Clock {
  @override
  DateTime now() => testNow;
}

void main() {
  late MockBookingRepository repository;
  late MockAuthSession session;
  late PayBooking pay;

  setUp(() {
    repository = MockBookingRepository();
    session = MockAuthSession();
    when(() => session.isEmailVerified).thenReturn(true);
    pay = PayBooking(repository, _FixedClock(), EmailVerificationGate(session));
  });

  test('rejects payment while the email is unverified', () async {
    when(() => session.isEmailVerified).thenReturn(false);

    final result = await pay(
      bookingView(status: BookingStatus.approved),
      momoNumber: '788123456',
    );

    expect((result as Failure<MomoReceipt>).failure, isA<ValidationFailure>());
    verifyNever(
      () => repository.pay(any(), momoNumber: any(named: 'momoNumber')),
    );
  });

  test('rejects a booking that is not approved', () async {
    final result = await pay(
      bookingView(status: BookingStatus.pending),
      momoNumber: '788123456',
    );

    expect((result as Failure<MomoReceipt>).failure, isA<ConflictFailure>());
    verifyNever(
      () => repository.pay(any(), momoNumber: any(named: 'momoNumber')),
    );
  });

  test('rejects an invalid MoMo number', () async {
    final result = await pay(
      bookingView(status: BookingStatus.approved),
      momoNumber: '123',
    );

    expect((result as Failure<MomoReceipt>).failure, isA<ValidationFailure>());
  });

  test('rejects payment after the deadline', () async {
    final result = await pay(
      bookingView(
        status: BookingStatus.approved,
        payDeadline: testNow.subtract(const Duration(minutes: 1)),
      ),
      momoNumber: '788123456',
    );

    expect((result as Failure<MomoReceipt>).failure, isA<ConflictFailure>());
  });

  test('charges the locked amount through the repository', () async {
    const receipt = MomoReceipt(reference: 'MOMO-1');
    when(() => repository.pay('booking-1', momoNumber: '788123456'))
        .thenAnswer((_) async => const Result.success(receipt));

    final result = await pay(
      bookingView(
        status: BookingStatus.approved,
        payDeadline: testNow.add(const Duration(hours: 1)),
      ),
      momoNumber: ' 788123456 ',
    );

    expect((result as Success<MomoReceipt>).value, receipt);
    verify(() => repository.pay('booking-1', momoNumber: '788123456'))
        .called(1);
  });
}
