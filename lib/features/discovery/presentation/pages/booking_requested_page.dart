import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/error_view.dart';
import 'package:veloce/core/widgets/loading_view.dart';
import 'package:veloce/core/widgets/primary_button.dart';
import 'package:veloce/core/widgets/status_chip.dart';

import '../bloc/booking_requested_cubit.dart';

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
        appBar: AppBar(
          title: const Text('Request sent'),
          automaticallyImplyLeading: false,
        ),
        body: switch (state) {
          BookingRequestedLoading() => const LoadingView(),
          BookingRequestedFailure(:final error) => ErrorView(
            message: error.message,
            onRetry: () => context.read<BookingRequestedCubit>().load(),
          ),
          BookingRequestedLoaded(:final booking) => _Confirmation(
            reference: booking.reference,
          ),
        },
      ),
    );
  }
}

class _Confirmation extends StatelessWidget {
  const _Confirmation({required this.reference});

  final String reference;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        const SizedBox(height: AppSpacing.xl),
        Icon(
          Icons.check_circle_outline_rounded,
          size: 72,
          color: colors.brandDeep,
        ),
        const SizedBox(height: AppSpacing.lg),
        const Text(
          'Your request is pending approval',
          style: AppTextStyles.title,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'The owner has 24 hours to respond. Nothing is charged until '
          'they approve and you pay.',
          style: AppTextStyles.body.copyWith(color: colors.muted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: StatusChip(label: reference, tone: StatusTone.info),
        ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: 'View in My Activity',
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
