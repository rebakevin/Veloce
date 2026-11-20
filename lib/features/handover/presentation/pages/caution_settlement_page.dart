import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:veloce/core/data/services/booking_lookup.dart';
import 'package:veloce/core/domain/entities/booking.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/domain/enums/caution_decision.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/handover/domain/repositories/handover_repository.dart';
import 'package:veloce/features/handover/domain/services/late_fee_calculator.dart';

import '../bloc/settlement_cubit.dart';
import '../bloc/settlement_state.dart';

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
        appBar: AppBar(title: const Text('Caution settlement')),
        body: StreamBuilder<Result<Booking>>(
          stream: GetIt.I<BookingLookup>().watch(bookingId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData) {
              return const Center(
                child: Text('Unable to load booking details.'),
              );
            }

            return snapshot.data!.when(
              success: (booking) {
                return _buildSettlement(context, booking, userId);
              },
              failure: (failure) {
                return Center(child: Text(failure.message));
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

    final returnedAt = booking.returnedAt;

    final lateDays = returnedAt == null
        ? 0
        : LateFeeCalculator.calculateLateDays(
            dueAt: booking.endDate,
            returnedAt: returnedAt,
          );

    final lateFee = LateFeeCalculator.calculateLateFee(
      rentalFee: booking.rentalFee,
      lateDays: lateDays,
      cautionFee: booking.cautionFee,
      waived: booking.lateFeeWaived,
    );

    final refundAmount = booking.cautionFee - lateFee;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Return settlement',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Review the caution fee and any late charges before completing the booking.',
          ),
          const SizedBox(height: 24),
          _amountRow('Caution fee', booking.cautionFee),
          _amountRow('Late days', lateDays, isCurrency: false),
          _amountRow('Late fee', lateFee),
          const Divider(height: 28),
          _amountRow('Caution refund', refundAmount, isBold: true),
          const SizedBox(height: 24),

          if (isOwner &&
              booking.status == BookingStatus.returning &&
              bothReturned) ...[
            const Text(
              'Confirm that the vehicle was returned without damage or other issues.',
            ),
            const SizedBox(height: 16),
            _actionButton(
              label: 'Confirm no issues',
              onPressed: userId == null
                  ? null
                  : () => cubit.markNoIssue(userId: userId),
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
          ] else if (booking.status == BookingStatus.completed) ...[
            const Text(
              'This booking has been completed.',
              style: TextStyle(fontWeight: FontWeight.bold),
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

  Widget _amountRow(
    String label,
    int amount, {
    bool isCurrency = true,
    bool isBold = false,
  }) {
    final value = isCurrency ? '$amount RWF' : '$amount days';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
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
