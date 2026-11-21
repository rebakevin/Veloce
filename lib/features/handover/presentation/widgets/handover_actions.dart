import '../../../../core/domain/entities/booking.dart';
import '../../../../core/domain/enums/booking_status.dart';
import '../../../../core/domain/enums/caution_decision.dart';
import '../../../../core/navigation/route_names.dart';

/// One row of the handover section: a link to a screen, a waiting row (not
/// tappable) or plain information (no route).
class HandoverAction {
  const HandoverAction({
    required this.title,
    required this.description,
    this.route,
    this.enabled = true,
  });

  final String title;
  final String description;

  /// Null for a plain information row.
  final String? route;
  final bool enabled;
}

/// What [userId] can do next on [booking], per status and role. Exactly one
/// screen handles each state, so every link leads to a usable screen:
///
/// - the owner settles (no issue or a claim) from `/settle` while returning,
/// - after a claim, both sides use `/claim`; after no issue the renter
///   acknowledges on `/settle`.
List<HandoverAction> handoverActionsFor(Booking booking, String? userId) {
  final isOwner = userId == booking.ownerId;
  final isRenter = userId == booking.renterId;

  if (!isOwner && !isRenter) return const [];

  final id = booking.id;

  HandoverAction repairCost(String description) => HandoverAction(
    title: 'Repair costs',
    description: description,
    route: RouteNames.bookingRepairCost(id),
  );

  switch (booking.status) {
    case BookingStatus.confirmed:
      final confirmed = isOwner
          ? booking.ownerPickupConfirmedAt != null
          : booking.renterPickupConfirmedAt != null;

      return [
        HandoverAction(
          title: 'Pickup checklist',
          description: confirmed
              ? 'Waiting for the other side to confirm pickup.'
              : 'Inspect the vehicle and confirm pickup.',
          route: RouteNames.bookingPickup(id),
          enabled: !confirmed,
        ),
      ];

    case BookingStatus.active:
      return [
        HandoverAction(
          title: 'Return checklist',
          description: 'Complete the vehicle return inspection.',
          route: RouteNames.bookingReturn(id),
        ),
      ];

    case BookingStatus.returning:
      final confirmed = isOwner
          ? booking.ownerReturnConfirmedAt != null
          : booking.renterReturnConfirmedAt != null;
      final both =
          booking.ownerReturnConfirmedAt != null &&
          booking.renterReturnConfirmedAt != null;

      if (!both) {
        return [
          HandoverAction(
            title: 'Return confirmation',
            description: confirmed
                ? 'Waiting for the other side to confirm the return.'
                : 'Review the vehicle and confirm its return.',
            route: RouteNames.bookingReturn(id),
            enabled: !confirmed,
          ),
        ];
      }

      if (isOwner) {
        return [
          HandoverAction(
            title: 'Settle caution',
            description:
                'Report no issues, or make a claim. You can also waive or '
                'reduce the late fee.',
            route: RouteNames.bookingSettle(id),
          ),
        ];
      }

      return const [
        HandoverAction(
          title: 'Return confirmed',
          description: 'Waiting for the owner to settle the caution.',
        ),
      ];

    case BookingStatus.review:
      final isNoIssue = booking.cautionDecision == CautionDecision.noIssue;

      if (isNoIssue) {
        return [
          if (isRenter)
            HandoverAction(
              title: 'Acknowledge settlement',
              description:
                  'The owner reported no issues. Acknowledge to get your '
                  'caution refund.',
              route: RouteNames.bookingSettle(id),
            )
          else ...[
            const HandoverAction(
              title: 'Waiting for the renter',
              description:
                  'No issues recorded. The renter must acknowledge the '
                  'settlement.',
            ),
            repairCost('Record repair expenses and receipt photos.'),
          ],
        ];
      }

      return [
        if (isRenter)
          HandoverAction(
            title: 'Respond to caution claim',
            description: 'Review the claim and agree or dispute it.',
            route: RouteNames.bookingClaim(id),
          )
        else ...[
          HandoverAction(
            title: 'Manage caution claim',
            description: 'Review the renter response, revise or refund.',
            route: RouteNames.bookingClaim(id),
          ),
          repairCost('Record repair expenses and receipt photos.'),
        ],
      ];

    case BookingStatus.completed:
      return [
        if (isOwner)
          repairCost('View or manage repair expenses.')
        else
          const HandoverAction(
            title: 'Rental completed',
            description: 'This rental has been completed.',
          ),
      ];

    case BookingStatus.pending ||
        BookingStatus.approved ||
        BookingStatus.declined ||
        BookingStatus.expired ||
        BookingStatus.cancelled:
      return const [];
  }
}
