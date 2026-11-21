import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/entities/ledger_entry.dart';
import 'package:veloce/core/domain/enums/party.dart';
import 'package:veloce/core/domain/enums/transaction_status.dart';
import 'package:veloce/core/domain/enums/transaction_type.dart';
import 'package:veloce/features/finances/domain/enums/renter_payment_kind.dart';

LedgerEntry _entry(TransactionType type, {String reference = 'b-1'}) =>
    LedgerEntry(
      id: 'tx',
      bookingId: 'b-1',
      vehicleId: 'car-1',
      ownerId: 'owner-1',
      renterId: 'renter-1',
      type: type,
      amount: 1000,
      fromParty: Party.veloce,
      toParty: Party.renter,
      reference: reference,
      status: TransactionStatus.success,
      at: DateTime(2026, 11, 10),
    );

void main() {
  group('RenterPaymentKind.classify', () {
    test('tells a cancellation refund from a caution refund', () {
      expect(
        RenterPaymentKind.classify(
          _entry(TransactionType.refund, reference: 'REFUND-VLC-0042'),
        ),
        RenterPaymentKind.cancellationRefund,
      );
      expect(
        RenterPaymentKind.classify(_entry(TransactionType.refund)),
        RenterPaymentKind.cautionRefund,
      );
    });

    test('maps charge, claim deduction and late fee', () {
      expect(
        RenterPaymentKind.classify(_entry(TransactionType.charge)),
        RenterPaymentKind.payment,
      );
      expect(
        RenterPaymentKind.classify(_entry(TransactionType.claimDeduction)),
        RenterPaymentKind.claimDeduction,
      );
      expect(
        RenterPaymentKind.classify(_entry(TransactionType.lateFee)),
        RenterPaymentKind.lateFee,
      );
    });

    test('hides release, platform fee and payout rows', () {
      for (final type in [
        TransactionType.release,
        TransactionType.platformFee,
        TransactionType.payout,
      ]) {
        expect(RenterPaymentKind.classify(_entry(type)), isNull);
      }
    });

    test('refunds are credits, the rest leave the renter', () {
      expect(RenterPaymentKind.cautionRefund.isCredit, isTrue);
      expect(RenterPaymentKind.cancellationRefund.isCredit, isTrue);
      expect(RenterPaymentKind.payment.isCredit, isFalse);
      expect(RenterPaymentKind.lateFee.isCredit, isFalse);
    });
  });
}
