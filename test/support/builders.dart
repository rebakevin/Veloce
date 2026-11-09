import 'package:veloce/core/domain/entities/booking.dart';
import 'package:veloce/core/domain/entities/caution_claim.dart';
import 'package:veloce/core/domain/entities/claim_history_entry.dart';
import 'package:veloce/core/domain/entities/ledger_entry.dart';
import 'package:veloce/core/domain/entities/long_rate.dart';
import 'package:veloce/core/domain/entities/user_account.dart';
import 'package:veloce/core/domain/entities/vehicle.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/domain/enums/claim_response.dart';
import 'package:veloce/core/domain/enums/claim_status.dart';
import 'package:veloce/core/domain/enums/fuel_type.dart';
import 'package:veloce/core/domain/enums/party.dart';
import 'package:veloce/core/domain/enums/transaction_status.dart';
import 'package:veloce/core/domain/enums/transaction_type.dart';
import 'package:veloce/core/domain/enums/transmission.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/domain/enums/vehicle_status.dart';
import 'package:veloce/core/domain/enums/vehicle_type.dart';

final DateTime testNow = DateTime(2026, 11, 9, 10);

UserAccount aUser({UserRole role = UserRole.renter}) => UserAccount(
  id: 'user-1',
  role: role,
  name: 'Aline Uwase',
  photoUrl: null,
  verified: true,
  ratingAvg: 4.5,
  ratingCount: 2,
  completedCount: 1,
  createdAt: testNow,
);

Vehicle aVehicle() => Vehicle(
  id: 'car-1',
  ownerId: 'owner-1',
  plate: 'RAB 123 A',
  make: 'Toyota',
  model: 'Vitz',
  year: 2018,
  type: VehicleType.hatchback,
  transmission: Transmission.automatic,
  fuel: FuelType.petrol,
  seats: 5,
  features: const ['AC', 'Bluetooth'],
  description: 'Clean and economical.',
  dailyPrice: 80000,
  longRates: const [LongRate(fromDays: 3, pricePerDay: 70000)],
  cautionFee: 100000,
  neighbourhood: 'Kacyiru',
  fuelRule: 'Return with the same level',
  smoking: 'No smoking',
  extras: const [],
  rulesFileUrl: null,
  videoUrl: null,
  status: VehicleStatus.published,
  availableFrom: testNow,
  availableTo: testNow.add(const Duration(days: 30)),
  docsValidUntil: testNow.add(const Duration(days: 200)),
  ratingAvg: 0,
  ratingCount: 0,
  createdAt: testNow,
);

Booking aBooking({
  BookingStatus status = BookingStatus.pending,
  DateTime? expiresAt,
  DateTime? payDeadline,
  String id = 'booking-1',
}) => Booking(
  id: id,
  reference: 'VLC-0042',
  vehicleId: 'car-1',
  renterId: 'renter-1',
  ownerId: 'owner-1',
  startDate: testNow.add(const Duration(days: 2)),
  endDate: testNow.add(const Duration(days: 5)),
  days: 3,
  dailyRateApplied: 70000,
  rentalFee: 210000,
  cautionFee: 100000,
  platformFee: 2000,
  totalPayable: 310000,
  status: status,
  reason: null,
  payDeadline: payDeadline,
  expiresAt: expiresAt,
  agreementAckAt: null,
  ownerPickupConfirmedAt: null,
  renterPickupConfirmedAt: null,
  returnedAt: null,
  ownerReturnConfirmedAt: null,
  renterReturnConfirmedAt: null,
  lateDays: 0,
  lateFee: 0,
  lateFeeWaived: false,
  cautionDecision: null,
  renterOutcomeAckAt: null,
  completedAt: null,
  createdAt: testNow,
  updatedAt: testNow,
);

LedgerEntry aLedgerEntry(TransactionType type, int amount) => LedgerEntry(
  id: 'tx-${type.key}',
  bookingId: 'booking-1',
  vehicleId: 'car-1',
  ownerId: 'owner-1',
  renterId: 'renter-1',
  type: type,
  amount: amount,
  fromParty: Party.renter,
  toParty: Party.veloce,
  reference: 'MOMO-1',
  status: TransactionStatus.success,
  at: testNow,
);

CautionClaim aClaim() => CautionClaim(
  bookingId: 'booking-1',
  originalAmount: 50000,
  currentAmount: 40000,
  reason: 'Scratch on the door',
  evidenceUrls: const ['https://example.com/a.jpg'],
  renterResponse: ClaimResponse.disputed,
  history: [
    ClaimHistoryEntry(
      amount: 50000,
      reason: 'Scratch on the door',
      at: testNow,
      response: ClaimResponse.none,
    ),
  ],
  status: ClaimStatus.open,
  updatedAt: testNow,
);
