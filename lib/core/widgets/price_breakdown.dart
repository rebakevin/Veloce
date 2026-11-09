import 'package:flutter/material.dart';

import '../domain/services/price_quote.dart';
import '../formatting/formatters.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Itemised price of a rental. Renters see the total they pay; owners also see
/// the platform fee and what they receive ([showOwnerView]).
class PriceBreakdown extends StatelessWidget {
  const PriceBreakdown({
    required this.quote,
    super.key,
    this.showOwnerView = false,
  });

  final PriceQuote quote;
  final bool showOwnerView;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        _row(
          '${quote.days} day${quote.days == 1 ? '' : 's'} × ${Formatters.rwf(quote.dailyRateApplied)}',
          Formatters.rwf(quote.rentalFee),
        ),
        _row('Refundable caution', Formatters.rwf(quote.cautionFee)),
        if (showOwnerView) ...[
          _row('Platform fee', '- ${Formatters.rwf(quote.platformFee)}'),
          _row(
            'You earn',
            Formatters.rwf(quote.ownerReceives),
            emphasised: true,
          ),
        ] else
          _row(
            'Total to pay',
            Formatters.rwf(quote.totalPayable),
            emphasised: true,
          ),
        Divider(color: colors.sand),
      ],
    );
  }

  Widget _row(String label, String value, {bool emphasised = false}) {
    final style = emphasised ? AppTextStyles.cardTitle : AppTextStyles.body;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
