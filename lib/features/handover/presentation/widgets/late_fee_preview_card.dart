import 'package:flutter/material.dart';

import '../../../../core/domain/entities/booking.dart';
import '../../../../core/formatting/formatters.dart';
import '../../domain/services/late_fee_calculator.dart';

/// Shows the renter and owner what a late return costs before the return is
/// confirmed. The fee is capped at the caution fee and the owner may waive or
/// reduce it on the settle screen.
class LateFeePreviewCard extends StatelessWidget {
  const LateFeePreviewCard({
    required this.booking,
    required this.now,
    super.key,
  });

  final Booking booking;

  /// Stands in for the return time until the return has started.
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final lateDays = LateFeeCalculator.calculateLateDays(
      dueAt: booking.endDate,
      returnedAt: booking.returnedAt ?? now,
    );

    final lateFee = LateFeeCalculator.calculateLateFee(
      rentalFee: booking.rentalFee,
      lateDays: lateDays,
      cautionFee: booking.cautionFee,
      waived: booking.lateFeeWaived,
      ownerAdjustedFee: LateFeeCalculator.ownerAdjustedFeeOf(booking.lateFee),
    );

    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Late fee preview', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            if (lateDays == 0)
              const Text('On time: no late fee.')
            else ...[
              Text('Days late: $lateDays'),
              Text(
                booking.lateFeeWaived
                    ? 'Late fee: waived by the owner'
                    : 'Late fee: ${Formatters.rwf(lateFee)}',
              ),
              Text(
                'Capped at the caution fee (${Formatters.rwf(booking.cautionFee)}).',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
