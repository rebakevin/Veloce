import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/entities/long_rate.dart';
import 'package:veloce/core/domain/services/pricing_calculator.dart';

void main() {
  const calculator = PricingCalculator();
  final start = DateTime(2026, 11, 10);

  test('the return day is not charged and the minimum is one day', () {
    expect(calculator.chargedDays(start, DateTime(2026, 11, 13)), 3);
    expect(calculator.chargedDays(start, start), 1);
  });

  test('the matching tier applies to every day', () {
    final quote = calculator.quote(
      dailyPrice: 80000,
      longRates: const [
        LongRate(fromDays: 3, pricePerDay: 75000),
        LongRate(fromDays: 5, pricePerDay: 70000),
      ],
      cautionFee: 100000,
      start: start,
      end: DateTime(2026, 11, 15),
    );
    expect(quote.days, 5);
    expect(quote.dailyRateApplied, 70000);
    expect(quote.rentalFee, 350000);
    expect(quote.totalPayable, 450000);
    expect(quote.ownerReceives, 348000);
  });

  test('without a matching tier the daily price applies', () {
    final quote = calculator.quote(
      dailyPrice: 80000,
      longRates: const [LongRate(fromDays: 3, pricePerDay: 75000)],
      cautionFee: 0,
      start: start,
      end: DateTime(2026, 11, 12),
    );
    expect(quote.dailyRateApplied, 80000);
    expect(quote.rentalFee, 160000);
  });

  group('validateLongRates', () {
    String? validate(List<LongRate> rates) =>
        calculator.validateLongRates(dailyPrice: 80000, longRates: rates);

    test('accepts strictly decreasing tiers', () {
      expect(
        validate(const [
          LongRate(fromDays: 3, pricePerDay: 75000),
          LongRate(fromDays: 5, pricePerDay: 70000),
        ]),
        isNull,
      );
    });
    test(
      'rejects more than three, early start, non-decreasing and cheap tiers',
      () {
        expect(
          validate(const [
            LongRate(fromDays: 2, pricePerDay: 79000),
            LongRate(fromDays: 3, pricePerDay: 78000),
            LongRate(fromDays: 4, pricePerDay: 77000),
            LongRate(fromDays: 5, pricePerDay: 76000),
          ]),
          isNotNull,
        );
        expect(
          validate(const [LongRate(fromDays: 1, pricePerDay: 70000)]),
          isNotNull,
        );
        expect(
          validate(const [LongRate(fromDays: 3, pricePerDay: 80000)]),
          isNotNull,
        );
        expect(
          validate(const [LongRate(fromDays: 3, pricePerDay: 4000)]),
          isNotNull,
        );
      },
    );
  });
}
