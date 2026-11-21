import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/handover/domain/services/caution_settlement_calculator.dart';
import 'package:veloce/features/handover/domain/services/late_fee_calculator.dart';

final _due = DateTime.utc(2026, 5, 10, 9);

CautionSettlement _agreed({
  int rentalFee = 100000,
  int cautionFee = 100000,
  required int claim,
  Duration late = Duration.zero,
  bool waived = false,
}) {
  final result = CautionSettlementCalculator.forAgreedClaim(
    rentalFee: rentalFee,
    cautionFee: cautionFee,
    dueAt: _due,
    returnedAt: _due.add(late),
    claimAmount: claim,
    lateFeeWaived: waived,
  );
  return (result as Success<CautionSettlement>).value;
}

CautionSettlement _refund({
  int rentalFee = 100000,
  int cautionFee = 100000,
  Duration late = Duration.zero,
  bool waived = false,
}) {
  final result = CautionSettlementCalculator.forRefund(
    rentalFee: rentalFee,
    cautionFee: cautionFee,
    dueAt: _due,
    returnedAt: _due.add(late),
    lateFeeWaived: waived,
  );
  return (result as Success<CautionSettlement>).value;
}

void main() {
  ownerAdjustedGroup();

  group('refund (no issue or owner refund)', () {
    test('on time refunds the whole caution', () {
      final s = _refund();

      expect(s.lateFee, 0);
      expect(s.claimDeduction, 0);
      expect(s.refund, 100000);
      expect(s.total, 100000);
    });

    test('one day late charges 30% of the rental fee, refunds the rest', () {
      final s = _refund(late: const Duration(hours: 5));

      expect(s.lateDays, 1);
      expect(s.lateFee, 30000);
      expect(s.refund, 70000);
      expect(s.total, 100000);
    });

    test('a waived late fee refunds the whole caution', () {
      final s = _refund(late: const Duration(days: 2), waived: true);

      expect(s.lateDays, 2);
      expect(s.lateFee, 0);
      expect(s.refund, 100000);
    });

    test('the late fee is capped at the caution, leaving a zero refund', () {
      final s = _refund(late: const Duration(days: 4));

      expect(s.lateFee, 100000);
      expect(s.refund, 0);
      expect(s.total, 100000);
    });
  });

  group('agreed claim', () {
    test('deducts the claim and refunds the remainder', () {
      final s = _agreed(claim: 60000);

      expect(s.claimDeduction, 60000);
      expect(s.lateFee, 0);
      expect(s.refund, 40000);
      expect(s.total, 100000);
    });

    test('the late fee only uses what the claim leaves of the caution', () {
      final s = _agreed(claim: 80000, late: const Duration(days: 1));

      expect(s.lateFee, 20000);
      expect(s.refund, 0);
      expect(s.total, 100000);
    });

    test('a claim equal to the caution leaves no late fee and no refund', () {
      final s = _agreed(claim: 100000, late: const Duration(days: 3));

      expect(s.lateFee, 0);
      expect(s.refund, 0);
    });

    test('a claim above the caution throws instead of overdrawing', () {
      expect(() => _agreed(claim: 100001), throwsArgumentError);
    });
  });

  test('refund and claim never go negative across a sweep of cases', () {
    for (final claim in [0, 1, 50000, 99999, 100000]) {
      for (final days in [0, 1, 2, 3, 10]) {
        for (final waived in [false, true]) {
          final s = _agreed(
            claim: claim,
            late: Duration(days: days),
            waived: waived,
          );

          expect(s.refund, greaterThanOrEqualTo(0));
          expect(s.lateFee, greaterThanOrEqualTo(0));
          expect(s.total, 100000);
        }
      }
    }
  });
}

void ownerAdjustedGroup() {
  group('owner adjusted late fee', () {
    final due = DateTime(2026, 11, 10);
    final returned = DateTime(2026, 11, 12);

    test('a reduced fee replaces the calculated one', () {
      final result = CautionSettlementCalculator.forRefund(
        rentalFee: 100000,
        cautionFee: 100000,
        dueAt: due,
        returnedAt: returned,
        lateFeeWaived: false,
        ownerAdjustedFee: 20000,
      );

      final s = (result as Success<CautionSettlement>).value;
      expect(s.lateFee, 20000);
      expect(s.refund, 80000);
      expect(s.total, 100000);
    });

    test('the cap with a claim still wins over a high adjustment', () {
      final result = CautionSettlementCalculator.forAgreedClaim(
        rentalFee: 100000,
        cautionFee: 100000,
        dueAt: due,
        returnedAt: returned,
        claimAmount: 60000,
        lateFeeWaived: false,
        ownerAdjustedFee: 69000,
      );

      final s = (result as Success<CautionSettlement>).value;
      expect(s.lateFee, 40000);
      expect(s.refund, 0);
    });

    test('a stored fee of 0 means no adjustment', () {
      expect(LateFeeCalculator.ownerAdjustedFeeOf(0), isNull);
      expect(LateFeeCalculator.ownerAdjustedFeeOf(15000), 15000);
    });
  });
}
