import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/features/handover/domain/services/late_fee_calculator.dart';

void main() {
  group('LateFeeCalculator', () {
    test('calculates late days by rounding up partial days', () {
      final dueAt = DateTime(2026, 11, 18, 10);

      expect(
        LateFeeCalculator.calculateLateDays(
          dueAt: dueAt,
          returnedAt: dueAt.add(const Duration(hours: 2)),
        ),
        1,
      );

      expect(
        LateFeeCalculator.calculateLateDays(
          dueAt: dueAt,
          returnedAt: dueAt.add(const Duration(days: 2)),
        ),
        2,
      );
    });

    test('returns zero when the booking is not late', () {
      final dueAt = DateTime(2026, 11, 18, 10);

      expect(
        LateFeeCalculator.calculateLateDays(dueAt: dueAt, returnedAt: dueAt),
        0,
      );
    });

    test('calculates the compounding late fee', () {
      final expectedFees = {1: 30000, 2: 69000, 3: 119700, 4: 185610};

      for (final entry in expectedFees.entries) {
        expect(
          LateFeeCalculator.calculateLateFee(
            rentalFee: 100000,
            lateDays: entry.key,
            cautionFee: 500000,
          ),
          entry.value,
        );
      }
    });

    test('does not exceed the remaining caution', () {
      expect(
        LateFeeCalculator.calculateLateFee(
          rentalFee: 100000,
          lateDays: 3,
          cautionFee: 100000,
          claimAmount: 50000,
        ),
        50000,
      );
    });

    test('allows the owner to reduce the late fee', () {
      expect(
        LateFeeCalculator.calculateLateFee(
          rentalFee: 100000,
          lateDays: 2,
          cautionFee: 200000,
          ownerAdjustedFee: 20000,
        ),
        20000,
      );
    });

    test('allows the owner to waive the late fee', () {
      expect(
        LateFeeCalculator.calculateLateFee(
          rentalFee: 100000,
          lateDays: 3,
          cautionFee: 200000,
          waived: true,
        ),
        0,
      );
    });
  });
}
