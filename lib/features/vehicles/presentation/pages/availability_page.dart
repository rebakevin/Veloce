import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/app_messenger.dart';
import 'package:veloce/core/widgets/date_range_field.dart';
import 'package:veloce/core/widgets/error_view.dart';
import 'package:veloce/core/widgets/loading_view.dart';
import 'package:veloce/core/widgets/page_app_bar.dart';
import 'package:veloce/core/widgets/primary_button.dart';
import 'package:veloce/core/widgets/section_header.dart';

import '../bloc/availability_bloc.dart';
import '../widgets/booked_days_list.dart';

/// Where the owner sets the one date range a car can be rented in.
class AvailabilityPage extends StatelessWidget {
  const AvailabilityPage({required this.vehicleId, super.key});

  final String vehicleId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PageAppBar(title: 'Availability'),
      body: SafeArea(
        child: BlocConsumer<AvailabilityBloc, AvailabilityState>(
          listener: _onState,
          builder: (context, state) => switch (state) {
            AvailabilityLoading() => const LoadingView(),
            AvailabilityFailure(:final message) => ErrorView(
              message: message,
              onRetry: () => context.read<AvailabilityBloc>().add(
                AvailabilityStarted(vehicleId),
              ),
            ),
            final AvailabilityLoaded loaded => _Editor(state: loaded),
          },
        ),
      ),
    );
  }

  void _onState(BuildContext context, AvailabilityState state) {
    if (state is! AvailabilityLoaded) return;
    if (state.notice != null) {
      GetIt.I<AppMessenger>().error(state.notice!);
      context.read<AvailabilityBloc>().add(const AvailabilityNoticeCleared());
    } else if (state.saved) {
      GetIt.I<AppMessenger>().success('Availability saved.');
      context.read<AvailabilityBloc>().add(const AvailabilityNoticeCleared());
    }
  }
}

class _Editor extends StatelessWidget {
  const _Editor({required this.state});

  final AvailabilityLoaded state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final from = state.from;
    final to = state.to;
    final problem = state.problem;
    final bloc = context.read<AvailabilityBloc>();
    final today = GetIt.I<Clock>().now();
    final booked = state.overview.bookedDays;
    final earliest = [
      DateTime(today.year, today.month, today.day),
      ?from,
      if (booked.isNotEmpty) booked.first.start,
    ].reduce((a, b) => a.isBefore(b) ? a : b);
    final latest = [
      today.add(const Duration(days: 365)),
      ?to,
      for (final range in booked) range.end,
    ].reduce((a, b) => a.isAfter(b) ? a : b);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      children: [
        Text(
          '${state.overview.vehicle.make} ${state.overview.vehicle.model}',
          style: AppTextStyles.cardTitle,
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Renters can book this car only inside one date range.',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: AppSpacing.lg),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'When can renters book this car?',
                  style: AppTextStyles.cardTitle,
                ),
                const SizedBox(height: AppSpacing.md),
                DateRangeField(
                  label: 'Available dates',
                  value: from == null || to == null
                      ? null
                      : DateTimeRange(start: from, end: to),
                  firstDate: earliest,
                  lastDate: latest,
                  errorText: problem,
                  onChanged: (range) => bloc.add(
                    AvailabilityRangeChanged(range.start, range.end),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Booked days'),
        BookedDaysList(days: booked),
        if (booked.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Booked days are locked. Your dates must cover them.',
            style: AppTextStyles.caption.copyWith(color: colors.muted),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: 'Save dates',
          isLoading: state.saving,
          onPressed: state.edited && problem == null && from != null
              ? () => bloc.add(const AvailabilitySaved())
              : null,
        ),
      ],
    );
  }
}
