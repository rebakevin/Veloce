import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/booking/domain/usecases/approve_booking.dart';

import '../support/booking_test_data.dart';

void main() {
  late MockBookingRepository repository;
  late ApproveBooking approve;

  setUp(() {
    repository = MockBookingRepository();
    approve = ApproveBooking(repository);
  });

  test('requires the reviewed tick', () async {
    final result = await approve('booking-1', reviewed: false);

    expect(result, isA<Failure<void>>());
    expect((result as Failure<void>).failure, isA<ValidationFailure>());
    verifyNever(() => repository.approve(any()));
  });

  test('calls the repository when reviewed', () async {
    when(() => repository.approve('booking-1'))
        .thenAnswer((_) async => const Result.success(null));

    final result = await approve('booking-1', reviewed: true);

    expect(result, isA<Success<void>>());
    verify(() => repository.approve('booking-1')).called(1);
  });

  test('passes a conflict failure through', () async {
    when(() => repository.approve('booking-1')).thenAnswer(
      (_) async => const Result.failure(
        ConflictFailure('This renter is already booked.'),
      ),
    );

    final result = await approve('booking-1', reviewed: true);

    expect(
      (result as Failure<void>).failure,
      const ConflictFailure('This renter is already booked.'),
    );
  });
}
