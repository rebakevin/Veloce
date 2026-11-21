import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/entities/ledger_entry.dart';
import 'package:veloce/core/domain/entities/repair_expense.dart';
import 'package:veloce/core/domain/enums/party.dart';
import 'package:veloce/core/domain/enums/transaction_status.dart';
import 'package:veloce/core/domain/enums/transaction_type.dart';
import 'package:veloce/features/finances/domain/entities/finance_transaction.dart';
import 'package:veloce/features/finances/domain/services/owner_finance_calculator.dart';

LedgerEntry _entry(
  TransactionType type,
  int amount, {
  String id = 'tx',
  String bookingId = 'b-1',
  String vehicleId = 'car-1',
  DateTime? at,
  TransactionStatus status = TransactionStatus.success,
}) => LedgerEntry(
  id: '$id-${type.key}',
  bookingId: bookingId,
  vehicleId: vehicleId,
  ownerId: 'owner-1',
  renterId: 'renter-1',
  type: type,
  amount: amount,
  fromParty: Party.veloce,
  toParty: Party.owner,
  reference: bookingId,
  status: status,
  at: at ?? DateTime(2026, 11, 10),
);

RepairExpense _repair(String id, int amount, {String bookingId = 'b-1'}) =>
    RepairExpense(
      id: id,
      bookingId: bookingId,
      vehicleId: 'car-1',
      ownerId: 'owner-1',
      amount: amount,
      description: 'Repair',
      receiptUrl: null,
      createdAt: DateTime(2026, 11, 12),
    );

List<FinanceTransaction> _build(
  List<LedgerEntry> ledger, {
  List<RepairExpense> repairs = const [],
  String? vehicleId,
}) => OwnerFinanceCalculator.build(
  ledger: ledger,
  repairs: repairs,
  periodStart: DateTime(2026, 11),
  periodEnd: DateTime(2026, 12),
  vehicleId: vehicleId,
);

int _earned(List<FinanceTransaction> list) => list
    .where((t) => t.type == FinanceEntryType.earned)
    .fold(0, (sum, t) => sum + t.amount);

void main() {
  group('OwnerFinanceCalculator earned', () {
    test('release minus the platform fee row plus late fee', () {
      final result = _build([
        _entry(TransactionType.release, 100000, id: 'a', bookingId: 'b-1'),
        _entry(TransactionType.platformFee, 2000, id: 'a', bookingId: 'b-1'),
        _entry(TransactionType.release, 50000, id: 'b', bookingId: 'b-2'),
        _entry(TransactionType.platformFee, 2000, id: 'b', bookingId: 'b-2'),
        _entry(TransactionType.lateFee, 30000, id: 'c', bookingId: 'b-2'),
      ]);
      expect(_earned(result), 176000);
    });

    test('uses the platform fee row, not a constant', () {
      final result = _build([
        _entry(TransactionType.release, 100000),
        _entry(TransactionType.platformFee, 5000),
      ]);
      expect(_earned(result), 95000);
    });

    test('falls back to the default fee when no fee row exists', () {
      final result = _build([_entry(TransactionType.release, 100000)]);
      expect(
        _earned(result),
        100000 - OwnerFinanceCalculator.fallbackPlatformFee,
      );
    });

    test('ignores failed rows and rows outside the period', () {
      final result = _build([
        _entry(
          TransactionType.release,
          100000,
          id: 'failed',
          status: TransactionStatus.failed,
        ),
        _entry(
          TransactionType.release,
          100000,
          id: 'old',
          at: DateTime(2026, 10, 31),
        ),
        _entry(
          TransactionType.release,
          100000,
          id: 'next',
          at: DateTime(2026, 12),
        ),
      ]);
      expect(result, isEmpty);
    });

    test('only counts the requested car', () {
      final result = _build([
        _entry(TransactionType.release, 100000, id: 'a', vehicleId: 'car-1'),
        _entry(TransactionType.release, 60000, id: 'b', vehicleId: 'car-2'),
      ], vehicleId: 'car-2');
      expect(_earned(result), 58000);
    });
  });

  group('OwnerFinanceCalculator losses', () {
    test('repair cost is offset by the claim deduction of the booking', () {
      final result = _build(
        [_entry(TransactionType.claimDeduction, 40000)],
        repairs: [_repair('r1', 100000)],
      );
      final losses = result.where((t) => t.type == FinanceEntryType.loss);
      expect(losses.single.amount, 60000);
    });

    test('a repair fully covered by the deduction is no loss', () {
      final result = _build(
        [_entry(TransactionType.claimDeduction, 150000)],
        repairs: [_repair('r1', 100000)],
      );
      expect(result.where((t) => t.type == FinanceEntryType.loss), isEmpty);
    });

    test('one deduction is shared across repairs of the same booking', () {
      final result = _build(
        [_entry(TransactionType.claimDeduction, 50000)],
        repairs: [_repair('r1', 40000), _repair('r2', 40000)],
      );
      final total = result
          .where((t) => t.type == FinanceEntryType.loss)
          .fold(0, (sum, t) => sum + t.amount);
      expect(total, 30000);
    });
  });

  test('entries come newest first', () {
    final result = _build([
      _entry(
        TransactionType.release,
        100000,
        id: 'a',
        at: DateTime(2026, 11, 2),
      ),
      _entry(
        TransactionType.release,
        100000,
        id: 'b',
        at: DateTime(2026, 11, 20),
      ),
    ]);
    expect(result.first.date, DateTime(2026, 11, 20));
  });

  group('share', () {
    test('is the proportion of the total earned', () {
      expect(
        OwnerFinanceCalculator.share(carEarned: 60000, totalEarned: 100000),
        closeTo(0.6, 0.001),
      );
    });

    test('is 0 when nothing was earned', () {
      expect(OwnerFinanceCalculator.share(carEarned: 0, totalEarned: 0), 0.0);
    });
  });
}
