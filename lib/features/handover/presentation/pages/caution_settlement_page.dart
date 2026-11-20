import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:veloce/core/data/services/booking_lookup.dart';
import 'package:veloce/core/domain/entities/booking.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/domain/enums/caution_decision.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/handover/domain/repositories/handover_repository.dart';
import 'package:veloce/features/handover/domain/services/late_fee_calculator.dart';

class CautionSettlementPage extends StatefulWidget {
  const CautionSettlementPage({required this.bookingId, super.key});

  final String bookingId;

  @override
  State<CautionSettlementPage> createState() => _CautionSettlementPageState();
}

class _CautionSettlementPageState extends State<CautionSettlementPage> {
  bool _isLoading = false;
  String? _errorMessage;

  final _repository = GetIt.I<HandoverRepository>();
  final _session = GetIt.I<AuthSession>();

  Future<void> _markNoIssue() async {
    final userId = _session.currentUserId;
    if (userId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _repository.markNoIssue(
      bookingId: widget.bookingId,
      userId: userId,
    );

    if (!mounted) return;

    result.when(
      success: (_) {
        setState(() => _isLoading = false);
      },
      failure: (failure) {
        setState(() {
          _isLoading = false;
          _errorMessage = failure.message;
        });
      },
    );
  }

  Future<void> _acknowledgeNoIssue() async {
    final userId = _session.currentUserId;
    if (userId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _repository.acknowledgeNoIssue(
      bookingId: widget.bookingId,
      userId: userId,
    );

    if (!mounted) return;

    result.when(
      success: (_) {
        setState(() => _isLoading = false);
      },
      failure: (failure) {
        setState(() {
          _isLoading = false;
          _errorMessage = failure.message;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = _session.currentUserId;

    return Scaffold(
      appBar: AppBar(title: const Text('Caution settlement')),
      body: StreamBuilder<Result<Booking>>(
        stream: GetIt.I<BookingLookup>().watch(widget.bookingId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('Unable to load booking details.'));
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
    );
  }

  Widget _buildSettlement(
    BuildContext context,
    Booking booking,
    String? userId,
  ) {
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
            _actionButton(label: 'Confirm no issues', onPressed: _markNoIssue),
          ] else if (isRenter &&
              booking.status == BookingStatus.review &&
              isNoIssue) ...[
            const Text(
              'The owner reported no issues with the returned vehicle. Acknowledge this decision to complete the settlement.',
            ),
            const SizedBox(height: 16),
            _actionButton(
              label: 'Acknowledge and receive refund',
              onPressed: _acknowledgeNoIssue,
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

          if (_isLoading) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],

          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
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
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        child: Text(label),
      ),
    );
  }
}
