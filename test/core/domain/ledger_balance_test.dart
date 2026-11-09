import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/enums/transaction_type.dart';
import 'package:veloce/core/domain/services/ledger_balance.dart';

import '../../support/builders.dart';

void main() {
  test('held money after payment is the whole charge', () {
    final entries = [aLedgerEntry(TransactionType.charge, 310000)];
    expect(LedgerBalance.held(entries), 310000);
  });

  test('pickup releases the rental fee; the caution stays held', () {
    final entries = [
      aLedgerEntry(TransactionType.charge, 310000),
      aLedgerEntry(TransactionType.release, 210000),
      aLedgerEntry(TransactionType.platformFee, 2000),
      aLedgerEntry(TransactionType.payout, 208000),
    ];
    expect(LedgerBalance.held(entries), 100000);
  });

  test('a safe return refunds the caution and leaves nothing held', () {
    final entries = [
      aLedgerEntry(TransactionType.charge, 310000),
      aLedgerEntry(TransactionType.release, 210000),
      aLedgerEntry(TransactionType.platformFee, 2000),
      aLedgerEntry(TransactionType.payout, 208000),
      aLedgerEntry(TransactionType.refund, 100000),
    ];
    expect(LedgerBalance.held(entries), 0);
  });

  test('an agreed claim and late fee come out of the caution', () {
    final entries = [
      aLedgerEntry(TransactionType.charge, 310000),
      aLedgerEntry(TransactionType.release, 210000),
      aLedgerEntry(TransactionType.claimDeduction, 40000),
      aLedgerEntry(TransactionType.lateFee, 30000),
      aLedgerEntry(TransactionType.refund, 30000),
    ];
    expect(LedgerBalance.held(entries), 0);
  });

  test('cancelling before pickup refunds everything', () {
    final entries = [
      aLedgerEntry(TransactionType.charge, 310000),
      aLedgerEntry(TransactionType.refund, 310000),
    ];
    expect(LedgerBalance.held(entries), 0);
  });
}
