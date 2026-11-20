import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/booking/domain/usecases/decline_booking.dart';

import '../support/booking_test_data.dart';

void main() {
  late MockBookingRepository repository;
  late DeclineBooking decline;

  setUp(() {
    repository = MockBookingRepository();
    decline = DeclineBooking(repository);
  });

  test('a blank reason never reaches the repository', () async {
    final result = await decline('booking-1', reason: '  ');

    expect((result as Failure<void>).failure, isA<ValidationFailure>());
    verifyNever(() => repository.decline(any(), reason: any(named: 'reason')));
  });

  test('trims and sends the reason', () async {
    when(() => repository.decline('booking-1', reason: 'Booked'))
        .thenAnswer((_) async => const Result.success(null));

    final result = await decline('booking-1', reason: '  Booked  ');

    expect(result, isA<Success<void>>());
    verify(() => repository.decline('booking-1', reason: 'Booked')).called(1);
  });
}
