import 'package:veloce/core/domain/entities/booking.dart';
import 'package:veloce/core/domain/entities/vehicle.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/domain/enums/fuel_type.dart';
import 'package:veloce/core/domain/enums/transmission.dart';
import 'package:veloce/core/domain/enums/vehicle_status.dart';
import 'package:veloce/core/domain/enums/vehicle_type.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/vehicles/domain/repositories/vehicle_repository.dart';

Booking aBooking({
  BookingStatus status = BookingStatus.pending,
  DateTime? expiresAt,
}) {
  return Booking(
    id: 'booking-1',
    reference: 'REF-1',
    vehicleId: 'car-1',
    renterId: 'renter-1',
    ownerId: 'owner-1',
    startDate: DateTime(2026, 12, 1),
    endDate: DateTime(2026, 12, 5),
    days: 4,
    dailyRateApplied: 50000,
    rentalFee: 200000,
    cautionFee: 0,
    platformFee: 2000,
    totalPayable: 202000,
    status: status,
    reason: null,
    payDeadline: null,
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
    createdAt: DateTime(2026, 11, 1),
    updatedAt: DateTime(2026, 11, 1),
  );
}

Vehicle aVehicle({
  VehicleStatus status = VehicleStatus.paused,
  DateTime? docsValidUntil,
}) {
  return Vehicle(
    id: 'car-1',
    ownerId: 'owner-1',
    plate: 'RAB 123 A',
    make: 'Toyota',
    model: 'RAV4',
    year: 2020,
    type: VehicleType.values.first,
    transmission: Transmission.values.first,
    fuel: FuelType.values.first,
    seats: 5,
    features: const [],
    description: 'Clean and reliable.',
    dailyPrice: 50000,
    longRates: const [],
    cautionFee: 0,
    neighbourhood: 'Kimironko',
    fuelRule: 'Return as received',
    smoking: 'No smoking',
    extras: const [],
    rulesFileUrl: null,
    videoUrl: null,
    status: status,
    availableFrom: null,
    availableTo: null,
    docsValidUntil: docsValidUntil,
    ratingAvg: 0,
    ratingCount: 0,
    createdAt: DateTime(2026, 11, 1),
  );
}

class FixedClock implements Clock {
  const FixedClock(this._now);

  final DateTime _now;

  @override
  DateTime now() => _now;
}

class FakeVehicleRepository implements VehicleRepository {
  FakeVehicleRepository({this.bookings = const []});

  final List<Booking> bookings;
  final List<String> removed = [];
  final Map<String, VehicleStatus> statuses = {};

  @override
  @override
  Stream<Result<List<Vehicle>>> watchOwnerVehicles(String ownerId) =>
      const Stream.empty();

  @override
  Future<Result<List<Booking>>> bookingsOf(String vehicleId) async =>
      Result.success(bookings);

  @override
  Future<Result<void>> setStatus(String vehicleId, VehicleStatus status) async {
    statuses[vehicleId] = status;
    return const Result.success(null);
  }

  @override
  Future<Result<void>> remove(String vehicleId) async {
    removed.add(vehicleId);
    return const Result.success(null);
  }
}
