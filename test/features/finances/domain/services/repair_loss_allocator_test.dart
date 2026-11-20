import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/entities/repair_expense.dart';
import 'package:veloce/features/finances/domain/services/repair_loss_allocator.dart';

RepairExpense repair(String id, String bookingId, int amount, {int day = 1}) =>
    RepairExpense(
      id: id,
      bookingId: bookingId,
      vehicleId: 'car-1',
      ownerId: 'owner-1',
      amount: amount,
      description: 'Repair',
      receiptUrl: null,
      createdAt: DateTime(2026, 11, day),
    );

void main() {
  group('RepairLossAllocator', () {
    test('repair above the deduction loses the difference', () {
      final losses = RepairLossAllocator.allocate(
        repairs: [repair('r1', 'b1', 70000)],
        deductionByBooking: {'b1': 40000},
      );
      expect(losses['r1'], 30000);
    });

    test('repair below the deduction loses nothing', () {
      final losses = RepairLossAllocator.allocate(
        repairs: [repair('r1', 'b1', 60000)],
        deductionByBooking: {'b1': 100000},
      );
      expect(losses['r1'], 0);
    });

    test('repair without a deduction loses the full amount', () {
      final losses = RepairLossAllocator.allocate(
        repairs: [repair('r1', 'b1', 30000)],
        deductionByBooking: const {},
      );
      expect(losses['r1'], 30000);
    });

    test('two repairs on one booking offset the deduction once', () {
      final losses = RepairLossAllocator.allocate(
        repairs: [
          repair('r1', 'b1', 30000, day: 1),
          repair('r2', 'b1', 30000, day: 2),
        ],
        deductionByBooking: {'b1': 40000},
      );
      expect(losses['r1'], 0);
      expect(losses['r2'], 20000);
      expect(losses.values.reduce((a, b) => a + b), 60000 - 40000);
    });

    test('the oldest repair is offset first, whatever the input order', () {
      final losses = RepairLossAllocator.allocate(
        repairs: [
          repair('late', 'b1', 50000, day: 5),
          repair('early', 'b1', 50000, day: 2),
        ],
        deductionByBooking: {'b1': 50000},
      );
      expect(losses['early'], 0);
      expect(losses['late'], 50000);
    });

    test('a deduction on one booking does not offset another booking', () {
      final losses = RepairLossAllocator.allocate(
        repairs: [repair('r1', 'b1', 20000), repair('r2', 'b2', 20000)],
        deductionByBooking: {'b1': 20000},
      );
      expect(losses['r1'], 0);
      expect(losses['r2'], 20000);
    });

    test('total loss of a booking is max(0, repairs - deduction)', () {
      for (final deduction in [0, 10000, 55000, 90000, 200000]) {
        final losses = RepairLossAllocator.allocate(
          repairs: [
            repair('a', 'b1', 25000, day: 1),
            repair('b', 'b1', 30000, day: 2),
            repair('c', 'b1', 35000, day: 3),
          ],
          deductionByBooking: {'b1': deduction},
        );
        final total = losses.values.fold<int>(0, (sum, v) => sum + v);
        expect(total, (90000 - deduction).clamp(0, 90000));
      }
    });
  });
}
