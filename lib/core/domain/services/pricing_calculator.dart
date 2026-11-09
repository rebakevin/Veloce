import 'package:collection/collection.dart';

import '../../constants/app_constants.dart';
import '../entities/long_rate.dart';
import 'price_quote.dart';

/// Rental price rules shared by the listing preview, the request and payment.
class PricingCalculator {
  const PricingCalculator();

  /// Number of charged days. The return day is not charged; minimum 1.
  int chargedDays(DateTime start, DateTime end) {
    final startDay = DateTime.utc(start.year, start.month, start.day);
    final endDay = DateTime.utc(end.year, end.month, end.day);
    final days = endDay.difference(startDay).inDays;
    return days < 1 ? 1 : days;
  }

  /// The tier with the largest `fromDays <= days` wins and applies to every day.
  int dailyRateFor({
    required int dailyPrice,
    required List<LongRate> longRates,
    required int days,
  }) {
    final matching = longRates.where((tier) => tier.fromDays <= days);
    final best = matching.sortedBy<num>((tier) => tier.fromDays).lastOrNull;
    return best?.pricePerDay ?? dailyPrice;
  }

  PriceQuote quote({
    required int dailyPrice,
    required List<LongRate> longRates,
    required int cautionFee,
    required DateTime start,
    required DateTime end,
  }) {
    final days = chargedDays(start, end);
    final rate = dailyRateFor(
      dailyPrice: dailyPrice,
      longRates: longRates,
      days: days,
    );
    return PriceQuote(
      days: days,
      dailyRateApplied: rate,
      rentalFee: days * rate,
      platformFee: AppConstants.platformFee,
      cautionFee: cautionFee,
    );
  }

  /// Returns a user-facing message when the tiers break a rule, else `null`:
  /// at most 3 tiers, `fromDays >= 2`, each price below the daily price and the
  /// previous tier's price, and each price at least the minimum daily price.
  String? validateLongRates({
    required int dailyPrice,
    required List<LongRate> longRates,
  }) {
    if (longRates.length > AppConstants.maxLongRates) {
      return 'You can add at most ${AppConstants.maxLongRates} long-rental prices.';
    }
    final ordered = longRates.sortedBy<num>((tier) => tier.fromDays);
    var previousPrice = dailyPrice;
    var previousDays = AppConstants.minLongRateDays - 1;
    for (final tier in ordered) {
      if (tier.fromDays < AppConstants.minLongRateDays) {
        return 'Long-rental prices start from ${AppConstants.minLongRateDays} days.';
      }
      if (tier.fromDays <= previousDays) {
        return 'Each long-rental price needs a different number of days.';
      }
      if (tier.pricePerDay < AppConstants.minDailyPrice) {
        return 'Each price must be at least RWF ${AppConstants.minDailyPrice}.';
      }
      if (tier.pricePerDay >= previousPrice) {
        return 'Longer rentals must cost less per day than shorter ones.';
      }
      previousPrice = tier.pricePerDay;
      previousDays = tier.fromDays;
    }
    return null;
  }
}
