import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/domain/services/pricing_calculator.dart';
import 'package:veloce/core/theme/app_theme.dart';
import 'package:veloce/features/auth/auth.dart';
import 'package:veloce/features/discovery/domain/entities/booking_request_draft.dart';
import 'package:veloce/features/discovery/domain/usecases/create_booking_request.dart';
import 'package:veloce/features/discovery/presentation/bloc/request_bloc.dart';
import 'package:veloce/features/discovery/presentation/pages/booking_review_page.dart';

import '../../../../support/builders.dart';
import '../../support/discovery_fakes.dart';

class _FixedClock implements Clock {
  @override
  DateTime now() => testNow;
}

void main() {
  late BookingRequestDraft draft;

  setUp(() async {
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
    await GetIt.instance.reset();
    GetIt.instance.registerFactoryParam<RequestBloc, BookingRequestDraft, void>(
      (draft, _) => RequestBloc(
        createRequest: CreateBookingRequest(
          search: FakeSearchRepository(),
          requests: FakeRequestRepository(),
          pendingReviews: FakePendingReviewChecker(),
          emailGate: EmailVerificationGate(FakeAuthSession()),
          pricing: const PricingCalculator(),
          clock: _FixedClock(),
        ),
        session: FakeAuthSession(),
        draft: draft,
      ),
    );
  });

  tearDown(() => GetIt.instance.reset());

  testWidgets('the send button stays disabled until terms are ticked', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BookingReviewPage(vehicleId: 'car-1', draft: draft),
      ),
    );
    await tester.pumpAndSettle();

    FilledButton button() => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Send booking request'),
    );
    expect(button().onPressed, isNull);

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(button().onPressed, isNotNull);
  });
}
