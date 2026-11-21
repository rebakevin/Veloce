import 'package:flutter/material.dart';

import '../../../../core/domain/entities/booking.dart';
import '../../../../core/error/result.dart';
import '../../../../core/formatting/formatters.dart';
import '../../domain/services/caution_settlement_calculator.dart';
import '../../domain/services/late_fee_calculator.dart';

/// Caution fee, late fee, claim and refund for a booking, from the same
/// [CautionSettlementCalculator] the settlement writes use.
class SettlementBreakdown extends StatelessWidget {
  const SettlementBreakdown({
    required this.booking,
    required this.now,
    this.claimAmount = 0,
    super.key,
  });

  final Booking booking;

  /// Stands in for the return time until the return has started.
  final DateTime now;

  /// The agreed or pending claim, 0 when there is none.
  final int claimAmount;

  @override
  Widget build(BuildContext context) {
    final settlement = CautionSettlementCalculator.forAgreedClaim(
      rentalFee: booking.rentalFee,
      cautionFee: booking.cautionFee,
      dueAt: booking.endDate,
      returnedAt: booking.returnedAt ?? now,
      claimAmount: claimAmount,
      lateFeeWaived: booking.lateFeeWaived,
      ownerAdjustedFee: LateFeeCalculator.ownerAdjustedFeeOf(booking.lateFee),
    );

    return switch (settlement) {
      Failure<CautionSettlement>(:final failure) => Text(failure.message),
      Success<CautionSettlement>(:final value) => Column(
        children: [
          _row('Caution fee', Formatters.rwf(booking.cautionFee)),
          _row('Late days', '${value.lateDays} days'),
          _row(
            'Late fee',
            booking.lateFeeWaived ? 'Waived' : Formatters.rwf(value.lateFee),
          ),
          if (value.claimDeduction > 0)
            _row('Claim', Formatters.rwf(value.claimDeduction)),
          const Divider(height: 28),
          _row('Caution refund', Formatters.rwf(value.refund), bold: true),
        ],
      ),
    };
  }

  Widget _row(String label, String value, {bool bold = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}
