import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:veloce/core/data/services/booking_lookup.dart';
import 'package:veloce/core/domain/entities/booking.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/domain/enums/caution_decision.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/error_view.dart';
import 'package:veloce/core/widgets/loading_view.dart';
import 'package:veloce/features/handover/domain/repositories/handover_repository.dart';

import '../../../../core/widgets/page_app_bar.dart';
import '../bloc/settlement_cubit.dart';
import '../bloc/settlement_state.dart';
import '../widgets/settlement_breakdown.dart';

class CautionSettlementPage extends StatelessWidget {
  const CautionSettlementPage({required this.bookingId, super.key});

  final String bookingId;

  @override
  Widget build(BuildContext context) {
    final userId = GetIt.I<AuthSession>().currentUserId;

    return BlocProvider(
      create: (_) => SettlementCubit(
        bookingId: bookingId,
        repository: GetIt.I<HandoverRepository>(),
      ),
      child: Scaffold(
        appBar: const PageAppBar(title: 'Caution settlement'),
        body: StreamBuilder<Result<Booking>>(
          stream: GetIt.I<BookingLookup>().watch(bookingId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingView();
            }

            if (!snapshot.hasData) {
              return const ErrorView(
                message: 'Unable to load booking details.',
              );
            }

            return snapshot.data!.when(
              success: (booking) {
                return _buildSettlement(context, booking, userId);
              },
              failure: (failure) {
                return ErrorView(message: failure.message);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSettlement(
    BuildContext context,
    Booking booking,
    String? userId,
  ) {
    final cubit = context.read<SettlementCubit>();
    final isOwner = booking.ownerId == userId;
    final isRenter = booking.renterId == userId;

    final bothReturned =
        booking.ownerReturnConfirmedAt != null &&
        booking.renterReturnConfirmedAt != null;

    final isNoIssue = booking.cautionDecision == CautionDecision.noIssue;
    final now = GetIt.I<Clock>().now();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Return settlement', style: AppTextStyles.title),
          const SizedBox(height: 12),
          const Text(
            'Review the caution fee and any late charges before completing the booking.',
          ),
          const SizedBox(height: 24),
          SettlementBreakdown(booking: booking, now: now),
          const SizedBox(height: 24),

          if (isOwner &&
              booking.status == BookingStatus.returning &&
              bothReturned) ...[
            _LateFeeAdjuster(
              waived: booking.lateFeeWaived,
              onWaive: () => cubit.adjustLateFee(userId: userId!, waived: true),
              onReduce: (text) =>
                  cubit.adjustLateFee(userId: userId!, reducedFeeText: text),
              onRestore: () => cubit.adjustLateFee(userId: userId!),
            ),
            const Divider(height: 32),
            const Text(
              'Confirm that the vehicle was returned without damage or other issues, or make a claim.',
            ),
            const SizedBox(height: 16),
            _actionButton(
              label: 'Confirm no issues',
              onPressed: userId == null
                  ? null
                  : () => cubit.markNoIssue(userId: userId),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () =>
                  context.push(RouteNames.bookingClaim(booking.id)),
              child: const Text('Make a claim'),
            ),
          ] else if (isRenter &&
              booking.status == BookingStatus.review &&
              isNoIssue) ...[
            const Text(
              'The owner reported no issues with the returned vehicle. Acknowledge this decision to complete the settlement.',
            ),
            const SizedBox(height: 16),
            _actionButton(
              label: 'Acknowledge and receive refund',
              onPressed: userId == null
                  ? null
                  : () => cubit.acknowledgeNoIssue(userId: userId),
            ),
          ] else if (isOwner &&
              booking.status == BookingStatus.review &&
              isNoIssue) ...[
            const Text(
              'No issues recorded. Waiting for the renter to acknowledge the settlement.',
            ),
          ] else if (booking.status == BookingStatus.review) ...[
            OutlinedButton(
              onPressed: () =>
                  context.push(RouteNames.bookingClaim(booking.id)),
              child: const Text('Open the caution claim'),
            ),
          ] else if (booking.status == BookingStatus.completed) ...[
            const Text(
              'This booking has been completed.',
              style: AppTextStyles.cardTitle,
            ),
          ] else ...[
            const Text('The booking is not ready for this settlement action.'),
          ],

          BlocBuilder<SettlementCubit, SettlementState>(
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state.isLoading) ...[
                    const SizedBox(height: 16),
                    const Center(child: CircularProgressIndicator()),
                  ],
                  if (state.message != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      state.message!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return BlocBuilder<SettlementCubit, SettlementState>(
      builder: (context, state) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: state.isLoading ? null : onPressed,
            child: Text(label),
          ),
        );
      },
    );
  }
}

/// Owner controls for the late fee: waive it, reduce it, or restore it. Owns
/// the text controller only; the cubit validates and writes.
class _LateFeeAdjuster extends StatefulWidget {
  const _LateFeeAdjuster({
    required this.waived,
    required this.onWaive,
    required this.onReduce,
    required this.onRestore,
  });

  final bool waived;
  final VoidCallback onWaive;
  final void Function(String text) onReduce;
  final VoidCallback onRestore;

  @override
  State<_LateFeeAdjuster> createState() => _LateFeeAdjusterState();
}

class _LateFeeAdjusterState extends State<_LateFeeAdjuster> {
  final _reduced = TextEditingController();

  @override
  void dispose() {
    _reduced.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettlementCubit, SettlementState>(
      builder: (context, state) {
        final busy = state.isLoading;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Late fee', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _reduced,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Reduce late fee to (RWF)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: busy ? null : () => widget.onReduce(_reduced.text),
                  child: const Text('Reduce'),
                ),
                OutlinedButton(
                  onPressed: busy || widget.waived ? null : widget.onWaive,
                  child: const Text('Waive'),
                ),
                TextButton(
                  onPressed: busy ? null : widget.onRestore,
                  child: const Text('Restore'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
