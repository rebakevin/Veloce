import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_fields.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/domain/entities/booking.dart';
import '../../../core/domain/enums/notification_type.dart';
import '../../../core/domain/enums/party.dart';
import '../../../core/domain/enums/transaction_type.dart';
import '../../../core/domain/services/atomic_write.dart';
import '../../../core/domain/services/ledger_writer.dart';
import '../../../core/domain/services/notification_writer.dart';
import '../../../core/formatting/formatters.dart';
import '../domain/services/caution_settlement_calculator.dart';

/// How a booking reached `completed`.
enum CompletionPath {
  /// The owner reported no issue and the renter acknowledged.
  noIssue,

  /// The renter agreed to the owner's claim.
  agreedClaim,

  /// The owner refunded the caution after a disputed claim.
  refund,
}

/// Writes everything that belongs to a completed booking, so the three
/// completion paths (no issue, agreed claim, refund) cannot drift apart:
/// the settlement ledger rows, both parties' `completedCount`, and the
/// notifications. The caller updates the booking itself.
class CompletionWriter {
  const CompletionWriter({required this._ledger, required this._notifications});

  final LedgerWriter _ledger;
  final NotificationWriter _notifications;

  void write(
    AtomicWrite write, {
    required Booking completed,
    required CautionSettlement settlement,
    required CompletionPath path,
  }) {
    _writeLedger(write, completed, settlement);
    _countCompletion(write, completed);
    _notify(write, completed, settlement, path);
  }

  void _writeLedger(
    AtomicWrite write,
    Booking booking,
    CautionSettlement settlement,
  ) {
    void row(TransactionType type, int amount, Party to) {
      if (amount <= 0) return;

      _ledger.record(
        write,
        booking: booking,
        type: type,
        amount: amount,
        from: Party.veloce,
        to: to,
        reference: booking.id,
      );
    }

    row(TransactionType.claimDeduction, settlement.claimDeduction, Party.owner);
    row(TransactionType.lateFee, settlement.lateFee, Party.owner);
    row(TransactionType.refund, settlement.refund, Party.renter);
  }

  /// Adds exactly 1 to each party's `users.completedCount`.
  void _countCompletion(AtomicWrite write, Booking booking) {
    for (final userId in {booking.renterId, booking.ownerId}) {
      write.update(FirestorePaths.user(userId), {
        FirestoreFields.completedCount: FieldValue.increment(1),
      });
    }
  }

  void _notify(
    AtomicWrite write,
    Booking booking,
    CautionSettlement settlement,
    CompletionPath path,
  ) {
    void both({
      required NotificationType type,
      required String title,
      required String renterText,
      required String ownerText,
    }) {
      _notifications.send(
        write,
        userId: booking.renterId,
        type: type,
        title: title,
        text: renterText,
        bookingId: booking.id,
      );
      _notifications.send(
        write,
        userId: booking.ownerId,
        type: type,
        title: title,
        text: ownerText,
        bookingId: booking.id,
      );
    }

    switch (path) {
      case CompletionPath.noIssue:
        both(
          type: NotificationType.returnConfirmed,
          title: 'Caution settled',
          renterText:
              'You acknowledged the settlement. Your booking is now complete.',
          ownerText: 'The renter acknowledged the settlement. The booking is complete.',
        );
      case CompletionPath.agreedClaim:
        both(
          type: NotificationType.claimChanged,
          title: 'Caution claim settled',
          renterText: 'You agreed to the claim. The booking is complete.',
          ownerText: 'The renter agreed to your claim. Settlement is complete.',
        );
      case CompletionPath.refund:
        both(
          type: NotificationType.claimChanged,
          title: 'Caution fee refunded',
          renterText:
              'The owner refunded the caution fee. Your booking is complete.',
          ownerText: 'The caution fee refund has been recorded.',
        );
    }

    if (settlement.lateFee > 0) {
      both(
        type: NotificationType.lateFeeApplied,
        title: 'Late fee applied',
        renterText:
            'A late fee of ${Formatters.rwf(settlement.lateFee)} was taken from your caution fee.',
        ownerText:
            'A late fee of ${Formatters.rwf(settlement.lateFee)} was paid to you from the caution fee.',
      );
    }

    both(
      type: NotificationType.reviewDue,
      title: 'Review due',
      renterText: 'Rate your rental and the owner.',
      ownerText: 'Rate the renter of your vehicle.',
    );
  }
}
