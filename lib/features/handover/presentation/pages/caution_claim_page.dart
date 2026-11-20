import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:veloce/core/data/services/booking_lookup.dart';
import 'package:veloce/core/domain/entities/booking.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/domain/enums/claim_response.dart';
import 'package:veloce/core/domain/enums/claim_status.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/handover/domain/repositories/handover_repository.dart';

import '../bloc/caution_claim_cubit.dart';
import '../bloc/caution_claim_state.dart';

class CautionClaimPage extends StatelessWidget {
  const CautionClaimPage({required this.bookingId, super.key});

  final String bookingId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CautionClaimCubit(
        bookingId: bookingId,
        repository: GetIt.I<HandoverRepository>(),
      ),
      child: _CautionClaimView(bookingId: bookingId),
    );
  }
}

class _CautionClaimView extends StatelessWidget {
  const _CautionClaimView({required this.bookingId});

  final String bookingId;

  @override
  Widget build(BuildContext context) {
    final userId = GetIt.I<AuthSession>().currentUserId;

    return Scaffold(
      appBar: AppBar(title: const Text('Caution claim')),
      body: StreamBuilder<Result<Booking>>(
        stream: GetIt.I<BookingLookup>().watch(bookingId),
        builder: (context, bookingSnapshot) {
          if (bookingSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!bookingSnapshot.hasData) {
            return const Center(child: Text('Unable to load booking.'));
          }

          return bookingSnapshot.data!.when(
            success: (booking) {
              return BlocBuilder<CautionClaimCubit, CautionClaimState>(
                builder: (context, state) {
                  return switch (state.loadStatus) {
                    CautionClaimLoad.failed => const Center(
                      child: Text('Unable to load claim details.'),
                    ),
                    CautionClaimLoad.loading => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    CautionClaimLoad.loaded => _buildContent(
                      context,
                      booking,
                      state,
                      userId,
                    ),
                  };
                },
              );
            },
            failure: (failure) {
              return Center(child: Text(failure.message));
            },
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Booking booking,
    CautionClaimState state,
    String? userId,
  ) {
    final cubit = context.read<CautionClaimCubit>();
    final isOwner = booking.ownerId == userId;
    final isRenter = booking.renterId == userId;

    final bothReturned =
        booking.ownerReturnConfirmedAt != null &&
        booking.renterReturnConfirmedAt != null;

    final claim = state.claim;
    final claimExists = claim != null;
    final response = claim?.renterResponse ?? ClaimResponse.none;
    final claimStatus = claim?.status ?? ClaimStatus.open;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vehicle damage or issue claim',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (claim != null) ...[
            _detailRow('Claim amount', '${claim.currentAmount} RWF'),
            _detailRow('Reason', claim.reason),
            _detailRow('Claim status', claimStatus.key),
            _detailRow('Renter response', response.key),
            if (claim.evidenceUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Evidence references',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...claim.evidenceUrls.map(
                (url) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: SelectableText(url),
                ),
              ),
            ],
            const Divider(height: 32),
          ],
          if (isOwner &&
              booking.status == BookingStatus.returning &&
              bothReturned &&
              !claimExists) ...[
            _ClaimForm(
              title: 'Submit a caution claim',
              buttonLabel: 'Submit claim',
              isLoading: state.isLoading,
              onSubmit: (amount, reason, evidence) => userId == null
                  ? null
                  : cubit.submitClaim(
                      userId: userId,
                      amountText: amount,
                      reason: reason,
                      evidenceText: evidence,
                    ),
            ),
          ] else if (isRenter &&
              booking.status == BookingStatus.review &&
              claimExists &&
              claimStatus == ClaimStatus.open &&
              response == ClaimResponse.none) ...[
            const Text(
              'Review the owner claim and choose whether you agree or dispute it.',
            ),
            const SizedBox(height: 16),
            _actionButton(
              label: 'Agree to claim',
              onPressed: userId == null
                  ? null
                  : () => cubit.respondToClaim(
                      userId: userId,
                      response: ClaimResponse.agreed,
                    ),
              isLoading: state.isLoading,
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: state.isLoading || userId == null
                  ? null
                  : () => cubit.respondToClaim(
                      userId: userId,
                      response: ClaimResponse.disputed,
                    ),
              child: const Text('Dispute claim'),
            ),
          ] else if (isOwner &&
              booking.status == BookingStatus.review &&
              claimExists &&
              response == ClaimResponse.disputed &&
              claimStatus == ClaimStatus.open) ...[
            const Text(
              'The renter disputed the claim. You can revise the claim to the same or a lower amount, or refund the caution.',
            ),
            const SizedBox(height: 16),
            _ClaimForm(
              title: 'Revise claim',
              buttonLabel: 'Submit revised claim',
              isLoading: state.isLoading,
              onSubmit: (amount, reason, evidence) => userId == null
                  ? null
                  : cubit.reviseClaim(
                      userId: userId,
                      amountText: amount,
                      reason: reason,
                      evidenceText: evidence,
                    ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: state.isLoading || userId == null
                  ? null
                  : () => cubit.refundCaution(userId: userId),
              child: const Text('Refund caution'),
            ),
          ] else if (claimExists && claimStatus == ClaimStatus.settled) ...[
            const Text('The claim has been settled.'),
          ] else if (claimExists && claimStatus == ClaimStatus.refunded) ...[
            const Text('The caution has been refunded.'),
          ] else if (booking.status == BookingStatus.completed) ...[
            const Text('This booking has been completed.'),
          ] else if (claimExists && response == ClaimResponse.disputed) ...[
            const Text(
              'The claim is disputed and awaiting the owner’s next action.',
            ),
          ] else if (claimExists) ...[
            const Text('The claim is awaiting a response or settlement.'),
          ] else ...[
            const Text('The booking is not ready for a caution claim.'),
          ],
          if (state.isLoading) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
          if (state.errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              state.errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

Widget _actionButton({
  required String label,
  required VoidCallback? onPressed,
  required bool isLoading,
}) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: Text(label),
    ),
  );
}

/// Owns the text controllers only; validation and submission live in the
/// cubit, which the owner reaches through [onSubmit].
class _ClaimForm extends StatefulWidget {
  const _ClaimForm({
    required this.title,
    required this.buttonLabel,
    required this.isLoading,
    required this.onSubmit,
  });

  final String title;
  final String buttonLabel;
  final bool isLoading;
  final void Function(String amount, String reason, String evidence) onSubmit;

  @override
  State<_ClaimForm> createState() => _ClaimFormState();
}

class _ClaimFormState extends State<_ClaimForm> {
  final _amount = TextEditingController();
  final _reason = TextEditingController();
  final _evidence = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    _evidence.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _amount,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Claim amount (RWF)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _reason,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Reason for claim',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _evidence,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Evidence photo URLs (comma separated)',
            hintText: 'Paste uploaded photo URLs',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        _actionButton(
          label: widget.buttonLabel,
          onPressed: () =>
              widget.onSubmit(_amount.text, _reason.text, _evidence.text),
          isLoading: widget.isLoading,
        ),
      ],
    );
  }
}
