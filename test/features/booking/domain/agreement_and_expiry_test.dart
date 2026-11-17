import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/booking/domain/usecases/acknowledge_agreement.dart';
import 'package:veloce/features/booking/domain/usecases/expire_bookings.dart';

import '../support/booking_test_data.dart';

void main() {
  late MockBookingRepository repository;

  setUp(() => repository = MockBookingRepository());

  test('acknowledge forwards the booking id', () async {
    when(() => repository.acknowledgeAgreement('booking-1'))
        .thenAnswer((_) async => const Result.success(null));

    final result = await AcknowledgeAgreement(repository)('booking-1');

    expect(result, isA<Success<void>>());
    verify(() => repository.acknowledgeAgreement('booking-1')).called(1);
  });

  test('expire reports how many bookings were written', () async {
    when(() => repository.expireDueBookings())
        .thenAnswer((_) async => const Result.success(2));

    final result = await ExpireBookings(repository)();

    expect((result as Success<int>).value, 2);
  });
}
