import 'package:flutter/widgets.dart';

import 'package:veloce/core/domain/entities/booking.dart';
import 'package:veloce/core/domain/services/price_quote.dart';
import 'package:veloce/core/widgets/price_breakdown.dart';

/// Uses the rate and totals locked on the booking, never the current car price.
class BookingPriceBreakdown extends StatelessWidget {
  const BookingPriceBreakdown({
    required this.booking,
    super.key,
    this.showOwnerView = false,
  });

  final Booking booking;
  final bool showOwnerView;

  @override
  Widget build(BuildContext context) => PriceBreakdown(
    quote: PriceQuote(
      days: booking.days,
      dailyRateApplied: booking.dailyRateApplied,
      rentalFee: booking.rentalFee,
      platformFee: booking.platformFee,
      cautionFee: booking.cautionFee,
    ),
    showOwnerView: showOwnerView,
  );
}
