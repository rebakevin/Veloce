import 'dart:typed_data';

import 'package:veloce/core/domain/entities/booking.dart';
import 'package:veloce/core/domain/entities/document_photo.dart';
import 'package:veloce/core/domain/entities/long_rate.dart';
import 'package:veloce/core/domain/entities/vehicle.dart';
import 'package:veloce/core/domain/entities/vehicle_document.dart';
import 'package:veloce/core/domain/entities/vehicle_photo.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/domain/enums/document_kind.dart';
import 'package:veloce/core/domain/enums/fuel_type.dart';
import 'package:veloce/core/domain/enums/storage_bucket.dart';
import 'package:veloce/core/domain/enums/transmission.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/domain/enums/vehicle_status.dart';
import 'package:veloce/core/domain/enums/vehicle_type.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/domain/services/media_storage.dart';
import 'package:veloce/core/domain/services/verification_provider.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/vehicles/domain/entities/publish_request.dart';
import 'package:veloce/features/vehicles/domain/entities/wizard_draft.dart';
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
  FakeVehicleRepository({
    this.bookings = const [],
    this.vehicleStream,
    this.publishFails = false,
  });

  final List<Booking> bookings;
  final Stream<Result<List<Vehicle>>>? vehicleStream;
  final bool publishFails;
  final List<String> removed = [];
  final List<PublishRequest> published = [];
  final Map<String, VehicleStatus> statuses = {};
  final Map<String, Vehicle> vehicles = {};
  final Map<String, List<VehiclePhoto>> photos = {};
  final Map<String, List<VehicleDocument>> documents = {};
  final Map<String, (DateTime?, DateTime?)> availability = {};
  final List<VehicleDocument> upserted = [];

  @override
  Stream<Result<List<Vehicle>>> watchOwnerVehicles(String ownerId) =>
      vehicleStream ?? const Stream.empty();

  @override
  Future<Result<List<Booking>>> bookingsOf(String vehicleId) async =>
      Result.success(bookings);

  @override
  Future<Result<String>> publish(PublishRequest request) async {
    if (publishFails) return const Result.failure(NetworkFailure());
    published.add(request);
    return const Result.success('car-new');
  }

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

  @override
  Stream<Result<Vehicle>> watchVehicle(String vehicleId) {
    final vehicle = vehicles[vehicleId];
    return vehicle == null
        ? const Stream.empty()
        : Stream.value(Result.success(vehicle));
  }

  @override
  Future<Result<List<VehiclePhoto>>> photosOf(String vehicleId) async =>
      Result.success(photos[vehicleId] ?? const []);

  @override
  Future<Result<List<VehicleDocument>>> documentsOf(String vehicleId) async =>
      Result.success(documents[vehicleId] ?? const []);

  @override
  Future<Result<void>> update(
    Vehicle vehicle,
    List<VehiclePhoto> photos,
  ) async {
    vehicles[vehicle.id] = vehicle;
    this.photos[vehicle.id] = photos;
    return const Result.success(null);
  }

  @override
  Future<Result<void>> setAvailability(
    String vehicleId,
    DateTime? from,
    DateTime? to,
  ) async {
    availability[vehicleId] = (from, to);
    return const Result.success(null);
  }

  @override
  Future<Result<void>> upsertDocument(
    VehicleDocument document, {
    required DateTime? docsValidUntil,
    required VehicleStatus status,
  }) async {
    upserted.add(document);
    statuses[document.vehicleId] = status;
    return const Result.success(null);
  }
}

class FakeAuthSession implements AuthSession {
  const FakeAuthSession(this.currentUserId);

  @override
  final String? currentUserId;

  @override
  UserRole? get role => UserRole.owner;

  @override
  bool get isEmailVerified => true;

  @override
  Stream<void> get changes => const Stream.empty();
}

class FakeMediaStorage implements MediaStorage {
  FakeMediaStorage({this.failOnUpload});

  final int? failOnUpload;
  final List<String> uploaded = [];
  final List<String> deleted = [];

  @override
  Future<Result<String>> upload({
    required Uint8List bytes,
    required String extension,
    required StorageBucket bucket,
  }) async {
    if (uploaded.length == failOnUpload) {
      return const Result.failure(NetworkFailure());
    }
    final url = 'https://files.test/${uploaded.length}.$extension';
    uploaded.add(url);
    return Result.success(url);
  }

  @override
  Future<Result<void>> delete(String url) async {
    deleted.add(url);
    return const Result.success(null);
  }
}

class FakeVerificationProvider implements VerificationProvider {
  FakeVerificationProvider({this.succeeds = true});

  final bool succeeds;

  @override
  Future<Result<void>> verifyDocument({
    required String documentNumber,
    required String photoUrl,
  }) async {
    if (succeeds) return const Result<void>.success(null);
    return const Result<void>.failure(
      ValidationFailure('We could not verify this document. Try again.'),
    );
  }
}

List<DocumentPhoto> somePhotos(int count) => List.generate(
  count,
  (_) => DocumentPhoto(bytes: Uint8List(1), extension: 'jpg'),
);

WizardDraft aWizardDraft() {
  return WizardDraft(
    photos: somePhotos(3),
    plate: 'RAB 123 A',
    make: 'Toyota',
    model: 'RAV4',
    year: 2020,
    type: VehicleType.suv,
    neighbourhood: 'Kimironko',
    description: 'Clean and reliable.',
    transmission: Transmission.automatic,
    fuel: FuelType.petrol,
    seats: 5,
    dailyPrice: 50000,
    longRates: const [LongRate(fromDays: 3, pricePerDay: 45000)],
    cautionFee: 50000,
    fuelRule: 'Return as received',
    smoking: 'No smoking',
  );
}

DraftDocument aDraftDocument({DateTime? expiry}) {
  return DraftDocument(
    photo: somePhotos(1).first,
    number: 'N-1',
    plate: 'RAB 123 A',
    expiry: expiry ?? DateTime(2099),
    verified: true,
  );
}

WizardDraft aPublishableDraft() {
  return aWizardDraft().copyWith(
    documents: {
      DocumentKind.insurance: aDraftDocument(),
      DocumentKind.medical: aDraftDocument(),
    },
  );
}
