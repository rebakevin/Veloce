import 'package:flutter_test/flutter_test.dart';

import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/domain/services/pricing_calculator.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/auth/auth.dart';
import 'package:veloce/features/discovery/domain/entities/booking_request_draft.dart';
import 'package:veloce/features/discovery/domain/usecases/create_booking_request.dart';
import 'package:veloce/features/discovery/presentation/bloc/request_bloc.dart';

import '../../../../support/builders.dart';
import '../../support/discovery_fakes.dart';

class _FixedClock implements Clock {
  @override
  DateTime now() => testNow;
}

void main() {
  late FakeSearchRepository search;
  late FakeRequestRepository requests;
  late FakeAuthSession session;
  late BookingRequestDraft draft;

  setUp(() {
    search = FakeSearchRepository();
    requests = FakeRequestRepository();
    session = FakeAuthSession();
    final vehicle = aVehicle();
    final quote = const PricingCalculator().quote(
      dailyPrice: vehicle.dailyPrice,
      longRates: vehicle.longRates,
      cautionFee: vehicle.cautionFee,
      start: testNow,
      end: testNow.add(const Duration(days: 3)),
    );
    draft = BookingRequestDraft(
      vehicle: vehicle,
      start: testNow,
      end: testNow.add(const Duration(days: 3)),
      quote: quote,
    );
  });

  RequestBloc build() => RequestBloc(
    createRequest: CreateBookingRequest(
      search: search,
      requests: requests,
      pendingReviews: FakePendingReviewChecker(),
      emailGate: EmailVerificationGate(session),
      pricing: const PricingCalculator(),
      clock: _FixedClock(),
    ),
    session: session,
    draft: draft,
  );

  test('does not submit until the terms are accepted', () async {
    final bloc = build();
    bloc.add(const RequestSubmitted());
    await pumpEventQueue();
    expect(bloc.state, isA<RequestEditing>());
    expect((bloc.state as RequestEditing).failureMessage, contains('Tick'));
    await bloc.close();
  });

  test('submits with terms accepted and emits the booking', () async {
    final bloc = build();
    bloc
      ..add(const RequestTermsChanged(true))
      ..add(const RequestSubmitted());
    await pumpEventQueue();
    expect(bloc.state, isA<RequestSuccess>());
    expect(requests.lastRenterId, 'renter-1');
    await bloc.close();
  });

  test('shows the request failure message', () async {
    requests.createResult = const Result.failure(
      ConflictFailure('Those dates are already booked.'),
    );
    final bloc = build();
    bloc
      ..add(const RequestTermsChanged(true))
      ..add(const RequestSubmitted());
    await pumpEventQueue();
    expect(bloc.state, isA<RequestEditing>());
    expect(
      (bloc.state as RequestEditing).failureMessage,
      contains('already booked'),
    );
    await bloc.close();
  });

  test('flags a written total that differs from the reviewed one', () async {
    requests.createResult = Result.success(
      aBooking().copyWith(totalPayable: draft.quote.totalPayable + 5000),
    );
    final bloc = build();
    bloc
      ..add(const RequestTermsChanged(true))
      ..add(const RequestSubmitted());
    await pumpEventQueue();
    expect((bloc.state as RequestSuccess).priceChanged, isTrue);
    await bloc.close();
  });

  test('does not flag a matching total', () async {
    final bloc = build();
    bloc
      ..add(const RequestTermsChanged(true))
      ..add(const RequestSubmitted());
    await pumpEventQueue();
    expect((bloc.state as RequestSuccess).priceChanged, isFalse);
    await bloc.close();
  });
}
