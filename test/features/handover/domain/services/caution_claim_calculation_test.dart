import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/features/handover/domain/services/late_fee_calculator.dart';

void main() {
  group('Caution claim and late fee calculations', () {
    test('calculates a late fee within the remaining caution balance', () {
      final fee = LateFeeCalculator.calculateLateFee(
        rentalFee: 100000,
        lateDays: 2,
        cautionFee: 50000,
        claimAmount: 30000,
      );

      expect(fee, lessThanOrEqualTo(20000));
    });

    test('does not allow a claim above the caution fee', () {
      expect(
        () => LateFeeCalculator.calculateLateFee(
          rentalFee: 100000,
          lateDays: 1,
          cautionFee: 50000,
          claimAmount: 60000,
        ),
        throwsArgumentError,
      );
    });

    test('returns zero late fee when it is waived', () {
      final fee = LateFeeCalculator.calculateLateFee(
        rentalFee: 100000,
        lateDays: 3,
        cautionFee: 50000,
        waived: true,
      );

      expect(fee, 0);
    });

    test('does not exceed the caution balance after a claim', () {
      const cautionFee = 50000;
      const claimAmount = 40000;

      final lateFee = LateFeeCalculator.calculateLateFee(
        rentalFee: 100000,
        lateDays: 5,
        cautionFee: cautionFee,
        claimAmount: claimAmount,
      );

      expect(claimAmount + lateFee, lessThanOrEqualTo(cautionFee));
    });
  });
}
