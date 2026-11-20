import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/formatting/formatters.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

import '../bloc/activity_bloc.dart';

/// Slot owned by Phase 4: paid or approved rentals coming up.
class UpcomingRentalsCard extends StatelessWidget {
  const UpcomingRentalsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ActivityBloc>(
      create: (_) =>
          GetIt.instance<ActivityBloc>()..add(const ActivityStarted()),
      child: const _UpcomingRentalsView(),
    );
  }
}

class _UpcomingRentalsView extends StatelessWidget {
  const _UpcomingRentalsView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActivityBloc, ActivityState>(
      builder: (context, state) => _SlotCard(
        child: switch (state) {
          ActivityLoading() => const LinearProgressIndicator(),
          ActivityFailure(:final failure) => _SlotMessage(
            title: 'Upcoming rentals',
            message: failure.message,
            onTap: () =>
                context.read<ActivityBloc>().add(const ActivityStarted()),
            action: 'Retry',
          ),
          ActivityLoaded() => _Loaded(state: state),
        },
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.state});

  final ActivityLoaded state;

  @override
  Widget build(BuildContext context) {
    final upcoming =
        state.bookings
            .where(
              (view) =>
                  view.effectiveStatus == BookingStatus.confirmed ||
                  view.effectiveStatus == BookingStatus.approved,
            )
            .toList()
          ..sort((a, b) => a.booking.startDate.compareTo(b.booking.startDate));
    if (upcoming.isEmpty) {
      return _SlotMessage(
        title: 'Upcoming rentals',
        message: 'Paid and approved rentals appear here.',
        onTap: () => context.go(RouteNames.ownerActivity),
        action: 'Open activity',
      );
    }
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Upcoming rentals', style: AppTextStyles.cardTitle),
            ),
            Text(
              '${upcoming.length}',
              style: AppTextStyles.caption.copyWith(color: colors.muted),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final view in upcoming.take(2))
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(view.renter.name, style: AppTextStyles.body),
            subtitle: Text(
              '${view.vehicle.make} ${view.vehicle.model} · '
              '${Formatters.dateRange(view.booking.startDate, view.booking.endDate)}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RouteNames.booking(view.booking.id)),
          ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.go(RouteNames.ownerActivity),
            child: const Text('View all'),
          ),
        ),
      ],
    );
  }
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: child,
      ),
    );
  }
}

class _SlotMessage extends StatelessWidget {
  const _SlotMessage({
    required this.title,
    required this.message,
    required this.onTap,
    required this.action,
  });

  final String title;
  final String message;
  final VoidCallback onTap;
  final String action;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.cardTitle),
              const SizedBox(height: AppSpacing.xs),
              Text(
                message,
                style: AppTextStyles.body.copyWith(color: colors.muted),
              ),
            ],
          ),
        ),
        TextButton(onPressed: onTap, child: Text(action)),
      ],
    );
  }
}
