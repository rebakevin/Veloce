import 'package:flutter_test/flutter_test.dart';

import 'package:veloce/core/domain/entities/booking.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/domain/services/pricing_calculator.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/auth/auth.dart';
import 'package:veloce/features/discovery/domain/usecases/create_booking_request.dart';

import '../../../support/builders.dart';
import '../support/discovery_fakes.dart';

class _FixedClock implements Clock {
  @override
  DateTime now() => testNow;
}

void main() {
  late FakeSearchRepository search;
  late FakeRequestRepository requests;
  late FakePendingReviewChecker pending;
  late FakeAuthSession session;
  late CreateBookingRequest create;

  setUp(() {
    search = FakeSearchRepository();
    requests = FakeRequestRepository();
    pending = FakePendingReviewChecker();
    session = FakeAuthSession();
    create = CreateBookingRequest(
      search: search,
      requests: requests,
      pendingReviews: pending,
      emailGate: EmailVerificationGate(session),
      pricing: const PricingCalculator(),
      clock: _FixedClock(),
    );
  });

  Future<Result<Booking>> submit({
    String vehicleId = 'car-1',
    DateTime? start,
    DateTime? end,
  }) => create(
    renterId: 'renter-1',
    vehicleId: vehicleId,
    start: start ?? testNow,
    end: end ?? testNow.add(const Duration(days: 3)),
  );

  test('blocks an unverified email before reading the car', () async {
    session.verified = false;
    final result = await submit();
    expect(result, isA<Failure<Booking>>());
    expect((result as Failure<Booking>).failure, isA<ValidationFailure>());
    expect(search.detailCalls, isEmpty);
  });

  test('blocks the renter from requesting their own car', () async {
    search.detailResult = Result.success(
      aVehicleDetail(vehicle: aVehicle(ownerId: 'renter-1')),
    );
    final result = await submit();
    expect((result as Failure<Booking>).failure.message, contains('own car'));
  });

  test('rejects a past pickup date', () async {
    final result = await submit(
      start: testNow.subtract(const Duration(days: 1)),
      end: testNow.add(const Duration(days: 2)),
    );
    expect((result as Failure<Booking>).failure.message, contains('today'));
  });

  test('rejects dates outside the availability window', () async {
    search.detailResult = Result.success(
      aVehicleDetail(
        vehicle: aVehicle(
          availableFrom: testNow.add(const Duration(days: 5)),
          availableTo: testNow.add(const Duration(days: 9)),
        ),
      ),
    );
    final result = await submit();
    expect(
      (result as Failure<Booking>).failure.message,
      contains('availability'),
    );
  });

  test('rejects a booked date', () async {
    search.detailResult = Result.success(
      aVehicleDetail(
        blocks: [
          aCalendarBlock(
            start: testNow.add(const Duration(days: 1)),
            end: testNow.add(const Duration(days: 3)),
          ),
        ],
      ),
    );
    final result = await submit();
    expect(
      (result as Failure<Booking>).failure.message,
      contains('already booked'),
    );
  });

  test('rejects a renter who already holds a lock', () async {
    requests.locked = true;
    final result = await submit();
    expect(
      (result as Failure<Booking>).failure.message,
      contains('active booking'),
    );
  });

  test('rejects a renter with a pending review', () async {
    pending.pending = true;
    final result = await submit();
    expect(
      (result as Failure<Booking>).failure.message,
      contains('pending review'),
    );
  });

  test('writes a locked quote on success', () async {
    final result = await submit();
    expect(result, isA<Success<Booking>>());
    expect(requests.lastRenterId, 'renter-1');
    final quote = requests.lastDraft!.quote;
    expect(quote.days, 3);
    expect(quote.dailyRateApplied, 70000);
    expect(quote.rentalFee, 210000);
    expect(quote.platformFee, 2000);
    expect(quote.totalPayable, 310000);
  });
}
