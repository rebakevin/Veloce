import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/services/booking_lookup.dart';
import '../../../../core/domain/entities/booking.dart';
import '../../../../core/domain/enums/booking_status.dart';
import '../../../../core/domain/services/auth_session.dart';
import '../../../../core/navigation/route_names.dart';

class HandoverSection extends StatelessWidget {
  const HandoverSection({required this.bookingId, super.key});

  final String bookingId;

  @override
  Widget build(BuildContext context) {
    final bookingLookup = GetIt.I<BookingLookup>();

    return StreamBuilder(
      stream: bookingLookup.watch(bookingId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Card(
            child: ListTile(
              title: Text('Handover information unavailable'),
              subtitle: Text('Please try again later.'),
            ),
          );
        }

        return snapshot.data!.when(
          success: (booking) => _buildSection(context, booking),
          failure: (failure) => Card(
            child: ListTile(
              title: const Text('Could not load handover'),
              subtitle: Text(failure.message),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection(BuildContext context, Booking booking) {
    final userId = GetIt.I<AuthSession>().currentUserId;

    final isOwner = userId == booking.ownerId;
    final isRenter = userId == booking.renterId;

    if (!isOwner && !isRenter) {
      return const SizedBox.shrink();
    }

    final actions = <Widget>[];

    switch (booking.status) {
      case BookingStatus.confirmed:
        final alreadyConfirmed = isOwner
            ? booking.ownerPickupConfirmedAt != null
            : booking.renterPickupConfirmedAt != null;

        actions.add(
          _action(
            context,
            title: 'Pickup checklist',
            description: alreadyConfirmed
                ? 'Waiting for the other side to confirm pickup.'
                : 'Inspect the vehicle and confirm pickup.',
            route: RouteNames.bookingPickup(bookingId),
            enabled: !alreadyConfirmed,
          ),
        );

      case BookingStatus.active:
        actions.add(
          _action(
            context,
            title: 'Return checklist',
            description: 'Complete the vehicle return inspection.',
            route: RouteNames.bookingReturn(bookingId),
          ),
        );

      case BookingStatus.returning:
        final alreadyConfirmed = isOwner
            ? booking.ownerReturnConfirmedAt != null
            : booking.renterReturnConfirmedAt != null;

        final bothConfirmed =
            booking.ownerReturnConfirmedAt != null &&
            booking.renterReturnConfirmedAt != null;

        if (!bothConfirmed) {
          actions.add(
            _action(
              context,
              title: 'Return confirmation',
              description: alreadyConfirmed
                  ? 'Waiting for the other side to confirm the return.'
                  : 'Review the vehicle and confirm its return.',
              route: RouteNames.bookingReturn(bookingId),
              enabled: !alreadyConfirmed,
            ),
          );
        } else if (isOwner) {
          actions.add(
            _action(
              context,
              title: 'Settle caution',
              description:
                  'Choose whether to refund the caution or submit a claim.',
              route: RouteNames.bookingSettle(bookingId),
            ),
          );
        } else {
          actions.add(
            _information(
              'Return confirmed. Waiting for the owner to settle the caution.',
            ),
          );
        }

      case BookingStatus.review:
        if (isRenter) {
          actions.add(
            _action(
              context,
              title: 'Respond to caution claim',
              description: 'Review the claim and agree or dispute it.',
              route: RouteNames.bookingClaim(bookingId),
            ),
          );
        } else {
          actions.add(
            _action(
              context,
              title: 'Manage caution claim',
              description: 'Review, revise or refund the claim.',
              route: RouteNames.bookingSettle(bookingId),
            ),
          );
          actions.add(
            _action(
              context,
              title: 'Log repair cost',
              description: 'Record repair expenses and receipt photos.',
              route: RouteNames.bookingRepairCost(bookingId),
            ),
          );
        }

      case BookingStatus.completed:
        if (isOwner) {
          actions.add(
            _action(
              context,
              title: 'Repair costs',
              description: 'View or manage repair expenses.',
              route: RouteNames.bookingRepairCost(bookingId),
            ),
          );
        } else {
          actions.add(_information('This rental has been completed.'));
        }

      default:
        return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Handover and return',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...actions,
          ],
        ),
      ),
    );
  }

  Widget _action(
    BuildContext context, {
    required String title,
    required String description,
    required String route,
    bool enabled = true,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(description),
      trailing: enabled
          ? const Icon(Icons.arrow_forward_ios, size: 16)
          : const Icon(Icons.hourglass_empty),
      enabled: enabled,
      onTap: enabled ? () => context.push(route) : null,
    );
  }

  Widget _information(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(message),
    );
  }
}
