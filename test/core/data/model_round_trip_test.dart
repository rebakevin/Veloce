import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/data/models/booking_model.dart';
import 'package:veloce/core/data/models/caution_claim_model.dart';
import 'package:veloce/core/data/models/ledger_entry_model.dart';
import 'package:veloce/core/data/models/user_account_model.dart';
import 'package:veloce/core/data/models/vehicle_model.dart';
import 'package:veloce/core/domain/enums/transaction_type.dart';
import 'package:veloce/core/domain/enums/user_role.dart';

import '../../support/builders.dart';

void main() {
  test('user survives a round trip', () {
    final user = aUser(role: UserRole.owner);
    final map = UserAccountModel.toMap(user);
    expect(UserAccountModel.fromMap(user.id, map), user);
  });

  test('vehicle keeps long-rate tiers and explicit nulls', () {
    final vehicle = aVehicle();
    final map = VehicleModel.toMap(vehicle);
    expect(map['rulesFileUrl'], isNull);
    expect(map.containsKey('rulesFileUrl'), isTrue);
    expect(map['longRates'], [
      {'fromDays': 3, 'pricePerDay': 70000},
    ]);
    expect(VehicleModel.fromMap(vehicle.id, map), vehicle);
  });

  test('booking survives a round trip and stores enums as keys', () {
    final booking = aBooking();
    final map = BookingModel.toMap(booking);
    expect(map['status'], 'pending');
    expect(map['startDate'], isA<Timestamp>());
    expect(BookingModel.fromMap(booking.id, map), booking);
  });

  test('ledger entry uses snake_case type keys', () {
    final entry = aLedgerEntry(TransactionType.platformFee, 2000);
    final map = LedgerEntryModel.toMap(entry);
    expect(map['type'], 'platform_fee');
    expect(LedgerEntryModel.fromMap(entry.id, map), entry);
  });

  test('caution claim keeps its negotiation history', () {
    final claim = aClaim();
    final map = CautionClaimModel.toMap(claim);
    expect(CautionClaimModel.fromMap(claim.bookingId, map), claim);
  });

  test('a missing required field fails with the entity and field name', () {
    final map = BookingModel.toMap(aBooking())..remove('reference');
    expect(
      () => BookingModel.fromMap('booking-1', map),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('Booking.reference'),
        ),
      ),
    );
  });

  test('an unknown enum key is an error, not a default', () {
    final map = BookingModel.toMap(aBooking())..['status'] = 'teleported';
    expect(() => BookingModel.fromMap('booking-1', map), throwsArgumentError);
  });
}
