import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/services/booking_lookup.dart';
import '../../../../core/domain/entities/booking.dart';
import '../../../../core/domain/services/auth_session.dart';
import 'handover_actions.dart';

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
    final actions = handoverActionsFor(booking, userId);

    if (actions.isEmpty) return const SizedBox.shrink();

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
            for (final action in actions) _row(context, action),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, HandoverAction action) {
    final route = action.route;

    if (route == null) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(action.title),
        subtitle: Text(action.description),
      );
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(action.title),
      subtitle: Text(action.description),
      trailing: action.enabled
          ? const Icon(Icons.arrow_forward_ios, size: 16)
          : const Icon(Icons.hourglass_empty),
      enabled: action.enabled,
      onTap: action.enabled ? () => context.push(route) : null,
    );
  }
}
