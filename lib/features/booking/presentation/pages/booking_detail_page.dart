import 'package:flutter/material.dart';

import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/features/handover/handover.dart';
import 'package:veloce/features/reviews/reviews.dart';

/// Booking detail (Phase 4). Hosts the handover (Phase 5) and post-rental
/// (Phase 6) slots so those phases never edit this file.
class BookingDetailPage extends StatelessWidget {
  const BookingDetailPage({required this.bookingId, super.key});

  final String bookingId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        children: [
          const Text('Phase 4: booking detail and timeline'),
          Text(RouteNames.booking(bookingId)),
          const SizedBox(height: AppSpacing.lg),
          HandoverSection(bookingId: bookingId),
          const SizedBox(height: AppSpacing.lg),
          PostRentalSection(bookingId: bookingId),
        ],
      ),
    );
  }
}
