import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/booking/domain/services/cancellation_policy.dart';
import 'package:veloce/features/booking/domain/usecases/cancel_booking.dart';

import '../support/booking_test_data.dart';

void main() {
  late MockBookingRepository repository;
  late CancelBooking cancel;

  setUp(() {
    repository = MockBookingRepository();
    cancel = CancelBooking(repository, const CancellationPolicy());
  });

  test('does not cancel after pickup', () async {
    final result = await cancel(bookingView(status: BookingStatus.active));

    expect((result as Failure<void>).failure, isA<ConflictFailure>());
    verifyNever(() => repository.cancel(any(), reason: any(named: 'reason')));
  });

  test('cancels and passes the optional reason', () async {
    when(() => repository.cancel('booking-1', reason: 'Trip moved'))
        .thenAnswer((_) async => const Result.success(null));

    final result = await cancel(
      bookingView(status: BookingStatus.confirmed),
      reason: 'Trip moved',
    );

    expect(result, isA<Success<void>>());
    verify(() => repository.cancel('booking-1', reason: 'Trip moved'))
        .called(1);
  });
}
