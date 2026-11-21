import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/entities/booking.dart';
import 'package:veloce/core/domain/enums/notification_type.dart';
import 'package:veloce/core/domain/enums/party.dart';
import 'package:veloce/core/domain/enums/transaction_type.dart';
import 'package:veloce/core/domain/services/atomic_write.dart';
import 'package:veloce/core/domain/services/ledger_writer.dart';
import 'package:veloce/core/domain/services/notification_writer.dart';
import 'package:veloce/features/handover/data/completion_writer.dart';
import 'package:veloce/features/handover/domain/services/caution_settlement_calculator.dart';

import '../../../support/builders.dart';

class _Write implements AtomicWrite {
  final updates = <String, Map<String, dynamic>>{};

  @override
  String newId(String collectionPath) => 'id';
  @override
  void set(String documentPath, Map<String, dynamic> data) {}
  @override
  void update(String documentPath, Map<String, dynamic> data) =>
      updates[documentPath] = data;
  @override
  void delete(String documentPath) {}
  @override
  Future<void> commit() async {}
}

class _Ledger implements LedgerWriter {
  final rows = <(TransactionType, int, Party)>[];

  @override
  void record(
    AtomicWrite write, {
    required Booking booking,
    required TransactionType type,
    required int amount,
    required Party from,
    required Party to,
    String reference = '',
  }) => rows.add((type, amount, to));
}

class _Notifications implements NotificationWriter {
  final sent = <(String, NotificationType)>[];

  @override
  void send(
    AtomicWrite write, {
    required String userId,
    required NotificationType type,
    required String title,
    required String text,
    String? bookingId,
  }) => sent.add((userId, type));
}

void main() {
  late _Write write;
  late _Ledger ledger;
  late _Notifications notifications;
  late CompletionWriter writer;

  final booking = aBooking();

  setUp(() {
    write = _Write();
    ledger = _Ledger();
    notifications = _Notifications();
    writer = CompletionWriter(ledger: ledger, notifications: notifications);
  });

  CautionSettlement settlement({int late = 0, int claim = 0}) =>
      CautionSettlement(
        lateDays: late > 0 ? 1 : 0,
        lateFee: late,
        claimDeduction: claim,
        refund: booking.cautionFee - late - claim,
      );

  void run(CautionSettlement s, CompletionPath path) =>
      writer.write(write, completed: booking, settlement: s, path: path);

  test('no issue, on time: only a full refund and counts for both', () {
    run(settlement(), CompletionPath.noIssue);

    expect(ledger.rows, [
      (TransactionType.refund, booking.cautionFee, Party.renter),
    ]);
    expect(write.updates.keys, {'users/renter-1', 'users/owner-1'});
    expect(write.updates['users/renter-1'], {
      'completedCount': FieldValue.increment(1),
    });
  });

  test('agreed claim with a late fee: rows add up to the caution', () {
    run(settlement(late: 30000, claim: 40000), CompletionPath.agreedClaim);

    expect(ledger.rows.map((r) => r.$1), [
      TransactionType.claimDeduction,
      TransactionType.lateFee,
      TransactionType.refund,
    ]);
    expect(
      ledger.rows.fold<int>(0, (total, r) => total + r.$2),
      booking.cautionFee,
    );
  });

  test('a claim ate the whole caution: no refund row', () {
    run(settlement(claim: booking.cautionFee), CompletionPath.refund);

    expect(ledger.rows.map((r) => r.$1), [TransactionType.claimDeduction]);
  });

  test('notifications use claimChanged, lateFeeApplied and reviewDue', () {
    run(settlement(late: 30000, claim: 10000), CompletionPath.agreedClaim);

    final types = notifications.sent.map((n) => n.$2).toList();
    expect(
      types.where((t) => t == NotificationType.claimChanged),
      hasLength(2),
    );
    expect(
      types.where((t) => t == NotificationType.lateFeeApplied),
      hasLength(2),
    );
    expect(types.where((t) => t == NotificationType.reviewDue), hasLength(2));
    expect(
      notifications.sent
          .where((n) => n.$2 == NotificationType.reviewDue)
          .map((n) => n.$1),
      {'renter-1', 'owner-1'},
    );
  });

  test('no late fee, no lateFeeApplied notification', () {
    run(settlement(), CompletionPath.noIssue);

    expect(
      notifications.sent.map((n) => n.$2),
      isNot(contains(NotificationType.lateFeeApplied)),
    );
  });
}
