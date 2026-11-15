import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Finances calculations', () {
    test('Total earned computes release minus platform fee plus late fee', () {
      const platformFee = 2000;
      final release1 = 100000;
      final netRelease1 = max(0, release1 - platformFee); // 98,000
      final release2 = 50000;
      final netRelease2 = max(0, release2 - platformFee); // 48,000
      final lateFee = 30000;

      final totalEarned = netRelease1 + netRelease2 + lateFee;
      expect(totalEarned, equals(176000));
    });

    test(
      'Total losses computes repair minus claim deduction (caution offset)',
      () {
        // Scenario A: repair 70k vs deduction 40k -> loss 30k
        final repairA = 70000;
        final deductionA = 40000;
        final lossA = max(0, repairA - deductionA);
        expect(lossA, equals(30000));

        // Scenario B: repair 60k vs deduction 100k -> loss max(0, -40k) = 0
        final repairB = 60000;
        final deductionB = 100000;
        final lossB = max(0, repairB - deductionB);
        expect(lossB, equals(0));

        // Scenario C: repair 30k vs no deduction (0) -> loss 30k
        final repairC = 30000;
        final deductionC = 0;
        final lossC = max(0, repairC - deductionC);
        expect(lossC, equals(30000));

        final totalLosses = lossA + lossB + lossC;
        expect(totalLosses, equals(60000));
      },
    );

    test('Per-car share computes proportion of total earnings', () {
      final carAEarned = 60000;
      final carBEarned = 40000;
      final totalEarned = carAEarned + carBEarned;

      final shareA = totalEarned > 0 ? (carAEarned / totalEarned) : 0.0;
      final shareB = totalEarned > 0 ? (carBEarned / totalEarned) : 0.0;

      expect(shareA, closeTo(0.6, 0.001));
      expect(shareB, closeTo(0.4, 0.001));
    });

    test('Per-car share returns 0 when total earnings is 0', () {
      final totalEarned = 0;
      final carEarned = 0;
      final share = totalEarned > 0 ? (carEarned / totalEarned) : 0.0;
      expect(share, equals(0.0));
    });
  });
}
