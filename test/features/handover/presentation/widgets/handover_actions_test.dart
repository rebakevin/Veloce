import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/domain/enums/caution_decision.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/features/handover/presentation/widgets/handover_actions.dart';

import '../../../../support/builders.dart';

void main() {
  const owner = 'owner-1';
  const renter = 'renter-1';
  const id = 'booking-1';
  final done = DateTime(2026, 11, 18);

  String? routeOf(booking, String user) {
    final actions = handoverActionsFor(booking, user);
    return actions.isEmpty ? null : actions.first.route;
  }

  test('strangers and early statuses get nothing', () {
    expect(
      handoverActionsFor(aBooking(status: BookingStatus.confirmed), 'x'),
      isEmpty,
    );
    expect(handoverActionsFor(aBooking(), owner), isEmpty);
  });

  test('pickup waits once this side confirmed', () {
    final booking = aBooking(status: BookingStatus.confirmed)
        .copyWith(ownerPickupConfirmedAt: done);

    expect(handoverActionsFor(booking, owner).single.enabled, isFalse);
    expect(handoverActionsFor(booking, renter).single.enabled, isTrue);
    expect(routeOf(booking, renter), RouteNames.bookingPickup(id));
  });

  test('active goes to the return checklist', () {
    expect(
      routeOf(aBooking(status: BookingStatus.active), renter),
      RouteNames.bookingReturn(id),
    );
  });

  group('returning', () {
    final both = aBooking(status: BookingStatus.returning)
        .copyWith(ownerReturnConfirmedAt: done, renterReturnConfirmedAt: done);

    test('owner settles on the settle screen, renter only waits', () {
      expect(routeOf(both, owner), RouteNames.bookingSettle(id));
      expect(routeOf(both, renter), isNull);
    });

    test('until both confirmed, both use the return screen', () {
      final one = aBooking(status: BookingStatus.returning)
          .copyWith(ownerReturnConfirmedAt: done);

      expect(routeOf(one, renter), RouteNames.bookingReturn(id));
      expect(handoverActionsFor(one, owner).single.enabled, isFalse);
    });
  });

  group('review', () {
    final noIssue = aBooking(status: BookingStatus.review)
        .copyWith(cautionDecision: CautionDecision.noIssue);
    final claim = aBooking(status: BookingStatus.review)
        .copyWith(cautionDecision: CautionDecision.claim);

    test('no issue: renter acknowledges on settle', () {
      expect(routeOf(noIssue, renter), RouteNames.bookingSettle(id));
    });

    test('no issue: owner waits and can log repairs', () {
      final actions = handoverActionsFor(noIssue, owner);

      expect(actions.first.route, isNull);
      expect(actions.last.route, RouteNames.bookingRepairCost(id));
    });

    test('claim: both sides use the claim screen', () {
      expect(routeOf(claim, renter), RouteNames.bookingClaim(id));
      expect(routeOf(claim, owner), RouteNames.bookingClaim(id));
    });
  });

  test('completed: owner sees repair costs, renter is told it is done', () {
    final booking = aBooking(status: BookingStatus.completed);

    expect(routeOf(booking, owner), RouteNames.bookingRepairCost(id));
    expect(routeOf(booking, renter), isNull);
  });
}
