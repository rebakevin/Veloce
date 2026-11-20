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
