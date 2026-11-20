import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/entities/ledger_entry.dart';
import 'package:veloce/core/domain/enums/transaction_type.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/handover/domain/services/caution_settlement_calculator.dart';
import 'package:veloce/features/handover/domain/services/held_balance_guard.dart';
import 'package:veloce/features/handover/domain/services/pickup_release_calculator.dart';

import '../../../../support/builders.dart';

const _rentalFee = 210000;
const _caution = 100000;
final _due = DateTime.utc(2026, 5, 10, 9);

final _charge = aLedgerEntry(TransactionType.charge, _rentalFee + _caution);

List<LedgerEntry> _pickupEntries() {
  final release = (PickupReleaseCalculator.calculate(
    rentalFee: _rentalFee,
  ) as Success<PickupRelease>).value;

  return [
    aLedgerEntry(TransactionType.release, release.release),
    aLedgerEntry(TransactionType.platformFee, release.platformFee),
    aLedgerEntry(TransactionType.payout, release.payout),
  ];
}

List<LedgerEntry> _settlementEntries(CautionSettlement s) => [
  if (s.claimDeduction > 0)
    aLedgerEntry(TransactionType.claimDeduction, s.claimDeduction),
  if (s.lateFee > 0) aLedgerEntry(TransactionType.lateFee, s.lateFee),
  if (s.refund > 0) aLedgerEntry(TransactionType.refund, s.refund),
];

CautionSettlement _refundSettlement({required Duration late}) {
  final result = CautionSettlementCalculator.forRefund(
    rentalFee: _rentalFee,
    cautionFee: _caution,
    dueAt: _due,
    returnedAt: _due.add(late),
    lateFeeWaived: false,
  );
  return (result as Success<CautionSettlement>).value;
}

CautionSettlement _agreedSettlement(int claim, {required Duration late}) {
  final result = CautionSettlementCalculator.forAgreedClaim(
    rentalFee: _rentalFee,
    cautionFee: _caution,
    dueAt: _due,
    returnedAt: _due.add(late),
    claimAmount: claim,
    lateFeeWaived: false,
  );
  return (result as Success<CautionSettlement>).value;
}

void main() {
  final afterCharge = [_charge];
  final afterPickup = [_charge, ..._pickupEntries()];

  group('held balance after each path', () {
    test('pickup leaves exactly the caution held', () {
      final held = HeldBalanceGuard.heldAfter(
        existing: afterCharge,
        planned: _pickupEntries(),
      );

      expect(held, _caution);
    });

    test('no issue refund on time leaves nothing held', () {
      final planned = _settlementEntries(
        _refundSettlement(late: Duration.zero),
      );

      expect(
        HeldBalanceGuard.heldAfter(existing: afterPickup, planned: planned),
        0,
      );
    });

    test('no issue refund with a late fee leaves nothing held', () {
      final planned = _settlementEntries(
        _refundSettlement(late: const Duration(days: 1)),
      );

      expect(
        HeldBalanceGuard.heldAfter(existing: afterPickup, planned: planned),
        0,
      );
    });

    test('claim agreed with a late fee leaves nothing held', () {
      final planned = _settlementEntries(
        _agreedSettlement(60000, late: const Duration(days: 1)),
      );

      expect(
        HeldBalanceGuard.heldAfter(existing: afterPickup, planned: planned),
        0,
      );
    });

    test('claim disputed writes nothing, so the caution stays held', () {
      expect(
        HeldBalanceGuard.heldAfter(existing: afterPickup, planned: const []),
        _caution,
      );
    });

    test('re-claim writes nothing, so the caution stays held', () {
      // Only the claim document changes; no ledger entry is planned.
      expect(
        HeldBalanceGuard.staysNonNegative(
          existing: afterPickup,
          planned: const [],
        ),
        isTrue,
      );
    });

    test('owner refund after a dispute leaves nothing held', () {
      final planned = _settlementEntries(
        _refundSettlement(late: const Duration(days: 2)),
      );

      expect(
        HeldBalanceGuard.heldAfter(existing: afterPickup, planned: planned),
        0,
      );
    });

    test('a capped late fee plus claim never overdraws the caution', () {
      for (final claim in [0, 40000, 100000]) {
        final planned = _settlementEntries(
          _agreedSettlement(claim, late: const Duration(days: 6)),
        );

        expect(
          HeldBalanceGuard.staysNonNegative(
            existing: afterPickup,
            planned: planned,
          ),
          isTrue,
        );
      }
    });
  });

  test('detects an overdraw: paying out more than is held', () {
    final overdraw = [aLedgerEntry(TransactionType.refund, _caution + 1)];

    expect(
      HeldBalanceGuard.staysNonNegative(
        existing: afterPickup,
        planned: overdraw,
      ),
      isFalse,
    );
  });
}
