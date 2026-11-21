import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:veloce/core/domain/entities/booking.dart';
import 'package:veloce/core/formatting/formatters.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/error_view.dart';
import 'package:veloce/core/widgets/loading_view.dart';
import 'package:veloce/core/widgets/primary_button.dart';
import 'package:veloce/core/widgets/status_chip.dart';

import '../bloc/booking_requested_cubit.dart';
import '../widgets/info_card.dart';
import '../widgets/label_value_row.dart';

/// Confirmation shown after the atomic request write.
class BookingRequestedPage extends StatelessWidget {
  const BookingRequestedPage({required this.bookingId, super.key});

  final String bookingId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BookingRequestedCubit>(
      create: (_) =>
          GetIt.instance<BookingRequestedCubit>(param1: bookingId)..load(),
      child: const _RequestedBody(),
    );
  }
}

class _RequestedBody extends StatelessWidget {
  const _RequestedBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingRequestedCubit, BookingRequestedState>(
      builder: (context, state) => Scaffold(
        body: SafeArea(
          child: switch (state) {
            BookingRequestedLoading() => const LoadingView(),
            BookingRequestedFailure(:final error) => ErrorView(
              message: error.message,
              onRetry: () => context.read<BookingRequestedCubit>().load(),
            ),
            BookingRequestedLoaded(:final booking) => _Confirmation(
              booking: booking,
            ),
          },
        ),
      ),
    );
  }
}

class _Confirmation extends StatelessWidget {
  const _Confirmation({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl - 4,
        AppSpacing.xl,
        AppSpacing.xl - 4,
        AppSpacing.xl,
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.cautionWash,
              shape: BoxShape.circle,
            ),
            child: SizedBox.square(
              dimension: 72,
              child: Icon(
                Icons.send_outlined,
                size: 34,
                color: colors.cautionInk,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg + 2),
        Text(
          'Request sent',
          style: AppTextStyles.display.copyWith(
            color: colors.ink,
            fontSize: 32,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'The owner will review it. You have not been charged and the '
          'booking is not confirmed yet.',
          style: AppTextStyles.bodyLarge.copyWith(color: colors.muted),
        ),
        const SizedBox(height: AppSpacing.lg + 2),
        InfoCard(
          child: Column(
            spacing: AppSpacing.md - 2,
            children: [
              LabelValueRow(label: 'Reference', value: booking.reference),
              LabelValueRow(
                label: 'Dates',
                value: Formatters.dateRange(booking.startDate, booking.endDate),
              ),
              LabelValueRow(
                label: 'Status',
                value: booking.status.label,
                trailing: Align(
                  alignment: Alignment.centerRight,
                  child: StatusChip.booking(booking.status),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg + 2),
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.xs,
            children: [
              Text(
                'What happens next',
                style: AppTextStyles.bodySmall.copyWith(
                  color: colors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '1. The owner approves or declines.\n'
                '2. If approved, you pay with Mobile Money.\n'
                '3. Your booking is confirmed.',
                style: AppTextStyles.bodySmall.copyWith(color: colors.ink),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg + 2),
        PrimaryButton(
          label: 'View request in My Activity',
          onPressed: () => context.go(RouteNames.renterActivity),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          onPressed: () => context.go(RouteNames.renterHome),
          child: const Text('Keep exploring cars'),
        ),
      ],
    );
  }
}
