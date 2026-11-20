import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veloce/core/constants/firestore_fields.dart';
import 'package:veloce/core/constants/firestore_paths.dart';
import 'package:veloce/core/data/models/ledger_entry_model.dart';
import 'package:veloce/core/data/models/repair_expense_model.dart';
import 'package:veloce/core/data/models/vehicle_model.dart';
import 'package:veloce/core/data/services/booking_lookup.dart';
import 'package:veloce/core/data/services/failure_mapper.dart';
import 'package:veloce/core/data/services/vehicle_lookup.dart';
import 'package:veloce/core/domain/entities/vehicle.dart';
import 'package:veloce/core/domain/enums/transaction_type.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/error/result.dart';

import '../../domain/entities/car_finance_share.dart';
import '../../domain/entities/finance_summary.dart';
import '../../domain/entities/finance_transaction.dart';
import '../../domain/entities/renter_payment_item.dart';
import '../../domain/enums/finance_period.dart';
import '../../domain/repositories/finances_repository.dart';
import '../../domain/services/repair_loss_allocator.dart';

/// Firestore implementation of [FinancesRepository].
class FirestoreFinancesRepository implements FinancesRepository {
  const FirestoreFinancesRepository({
    required this._firestore,
    required this._vehicleLookup,
    required this._bookingLookup,
    required this._clock,
  });

  final FirebaseFirestore _firestore;
  final VehicleLookup _vehicleLookup;
  final BookingLookup _bookingLookup;
  final Clock _clock;

  static const int _platformFeeAmount = 2000;

  (DateTime start, DateTime end) _getPeriodRange(FinancePeriod period) {
    final now = _clock.now();
    if (period == FinancePeriod.thisMonth) {
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 1);
      return (start, end);
    } else {
      final start = DateTime(now.year, 1, 1);
      final end = DateTime(now.year + 1, 1, 1);
      return (start, end);
    }
  }

  @override
  Future<Result<FinanceSummary>> getOwnerFinances({
    required String ownerId,
    required FinancePeriod period,
    String? vehicleId,
  }) async {
    try {
      // 1. Fetch transactions for owner (and optional vehicle)
      Query<Map<String, dynamic>> txQuery = _firestore
          .collection(FirestorePaths.transactions)
          .where(FirestoreFields.ownerId, isEqualTo: ownerId);

      if (vehicleId != null) {
        txQuery = txQuery.where(
          FirestoreFields.vehicleId,
          isEqualTo: vehicleId,
        );
      }

      final txSnapshot = await txQuery
          .orderBy(FirestoreFields.at, descending: true)
          .get();
      final allTransactions = txSnapshot.docs
          .map((doc) => LedgerEntryModel.fromMap(doc.id, doc.data()))
          .toList();

      // 2. Fetch repair expenses for owner
      final repairSnapshot = await _firestore
          .collection(FirestorePaths.repairExpenses)
          .where(FirestoreFields.ownerId, isEqualTo: ownerId)
          .get();

      final allRepairExpenses = repairSnapshot.docs
          .map((doc) => RepairExpenseModel.fromMap(doc.id, doc.data()))
          .toList();

      // 3. Map claim deductions by bookingId
      final Map<String, int> claimDeductionsByBooking = {};
      for (final tx in allTransactions) {
        if (tx.type == TransactionType.claimDeduction) {
          claimDeductionsByBooking[tx.bookingId] =
              (claimDeductionsByBooking[tx.bookingId] ?? 0) + tx.amount;
        }
      }

      final (periodStart, periodEnd) = _getPeriodRange(period);
      final rawTransactions = <FinanceTransaction>[];

      // 4. Process Earned entries in selected period
      for (final tx in allTransactions) {
        if (tx.at.isBefore(periodStart) || !tx.at.isBefore(periodEnd)) {
          continue;
        }

        if (tx.type == TransactionType.release) {
          final earnedAmount = max(0, tx.amount - _platformFeeAmount);
          rawTransactions.add(
            FinanceTransaction(
              id: tx.id,
              bookingId: tx.bookingId,
              vehicleId: tx.vehicleId,
              type: FinanceEntryType.earned,
              amount: earnedAmount,
              date: tx.at,
            ),
          );
        } else if (tx.type == TransactionType.lateFee) {
          rawTransactions.add(
            FinanceTransaction(
              id: tx.id,
              bookingId: tx.bookingId,
              vehicleId: tx.vehicleId,
              type: FinanceEntryType.earned,
              amount: tx.amount,
              date: tx.at,
            ),
          );
        }
      }

      // 5. Process Loss entries in selected period. The deduction of a booking
      // is offset once across all its repairs, so every repair is allocated
      // first and the period filter comes after.
      final lossByRepair = RepairLossAllocator.allocate(
        repairs: allRepairExpenses,
        deductionByBooking: claimDeductionsByBooking,
      );
      for (final repair in allRepairExpenses) {
        if (vehicleId != null && repair.vehicleId != vehicleId) {
          continue;
        }

        if (repair.createdAt.isBefore(periodStart) ||
            !repair.createdAt.isBefore(periodEnd)) {
          continue;
        }

        final loss = lossByRepair[repair.id] ?? 0;
        if (loss > 0) {
          rawTransactions.add(
            FinanceTransaction(
              id: repair.id,
              bookingId: repair.bookingId,
              vehicleId: repair.vehicleId,
              type: FinanceEntryType.loss,
              amount: loss,
              date: repair.createdAt,
            ),
          );
        }
      }

      // 6. Sort newest first
      rawTransactions.sort((a, b) => b.date.compareTo(a.date));

      // 7. Enrich transactions with vehicle details
      final enrichedTransactions = <FinanceTransaction>[];
      final Map<String, Vehicle?> vehicleCache = {};

      for (final tx in rawTransactions) {
        if (!vehicleCache.containsKey(tx.vehicleId)) {
          final res = await _vehicleLookup.byId(tx.vehicleId);
          vehicleCache[tx.vehicleId] = res.valueOrNull;
        }
        final v = vehicleCache[tx.vehicleId];
        enrichedTransactions.add(
          FinanceTransaction(
            id: tx.id,
            bookingId: tx.bookingId,
            vehicleId: tx.vehicleId,
            type: tx.type,
            amount: tx.amount,
            date: tx.date,
            vehicleName: v != null ? '${v.make} ${v.model}' : null,
            vehiclePlate: v?.plate,
          ),
        );
      }

      final totalEarned = enrichedTransactions
          .where((t) => t.type == FinanceEntryType.earned)
          .fold<int>(0, (total, t) => total + t.amount);

      final totalLosses = enrichedTransactions
          .where((t) => t.type == FinanceEntryType.loss)
          .fold<int>(0, (total, t) => total + t.amount);

      // 8. Build per-car share breakdown
      final carShares = <CarFinanceShare>[];
      if (vehicleId == null) {
        final carsSnapshot = await _firestore
            .collection(FirestorePaths.vehicles)
            .where(FirestoreFields.ownerId, isEqualTo: ownerId)
            .get();

        final ownerCars = carsSnapshot.docs
            .map((doc) => VehicleModel.fromMap(doc.id, doc.data()))
            .toList();

        for (final car in ownerCars) {
          final carEarned = enrichedTransactions
              .where(
                (t) =>
                    t.vehicleId == car.id && t.type == FinanceEntryType.earned,
              )
              .fold<int>(0, (total, t) => total + t.amount);

          final carLosses = enrichedTransactions
              .where(
                (t) => t.vehicleId == car.id && t.type == FinanceEntryType.loss,
              )
              .fold<int>(0, (total, t) => total + t.amount);

          final share = totalEarned > 0 ? (carEarned / totalEarned) : 0.0;

          carShares.add(
            CarFinanceShare(
              vehicle: car,
              earned: carEarned,
              losses: carLosses,
              share: share,
            ),
          );
        }
      }

      return Result.success(
        FinanceSummary(
          totalEarned: totalEarned,
          totalLosses: totalLosses,
          transactions: enrichedTransactions,
          carShares: carShares,
        ),
      );
    } catch (e, st) {
      return Result.failure(mapToFailure(e, st));
    }
  }

  @override
  Future<Result<List<RenterPaymentItem>>> getRenterPayments(
    String renterId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.transactions)
          .where(FirestoreFields.renterId, isEqualTo: renterId)
          .orderBy(FirestoreFields.at, descending: true)
          .get();

      final entries = snapshot.docs
          .map((doc) => LedgerEntryModel.fromMap(doc.id, doc.data()))
          .toList();

      final items = <RenterPaymentItem>[];
      for (final entry in entries) {
        final bookingRes = await _bookingLookup.byId(entry.bookingId);
        final booking = bookingRes.valueOrNull;

        final vehicleRes = await _vehicleLookup.byId(entry.vehicleId);
        final vehicle = vehicleRes.valueOrNull;

        items.add(
          RenterPaymentItem(
            entry: entry,
            bookingReference: booking?.reference,
            vehicleName: vehicle != null
                ? '${vehicle.make} ${vehicle.model}'
                : null,
          ),
        );
      }

      return Result.success(items);
    } catch (e, st) {
      return Result.failure(mapToFailure(e, st));
    }
  }
}
