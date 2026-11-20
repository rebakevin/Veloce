import 'package:veloce/core/domain/entities/booking.dart';
import 'package:veloce/core/domain/entities/vehicle.dart';
import 'package:veloce/core/domain/entities/vehicle_document.dart';
import 'package:veloce/core/domain/entities/vehicle_photo.dart';
import 'package:veloce/core/domain/enums/vehicle_status.dart';
import 'package:veloce/core/error/result.dart';

import '../entities/publish_request.dart';

abstract interface class VehicleRepository {
  Stream<Result<List<Vehicle>>> watchOwnerVehicles(String ownerId);

  Future<Result<List<Booking>>> bookingsOf(String vehicleId);

  Future<Result<String>> publish(PublishRequest request);

  Future<Result<void>> setStatus(String vehicleId, VehicleStatus status);

  Future<Result<void>> remove(String vehicleId);

  Stream<Result<Vehicle>> watchVehicle(String vehicleId);

  Future<Result<List<VehiclePhoto>>> photosOf(String vehicleId);

  Future<Result<List<VehicleDocument>>> documentsOf(String vehicleId);

  /// Overwrites the listing fields of [vehicle] and replaces its photos in one
  /// batch. Rating fields, owner and creation date are left untouched.
  Future<Result<void>> update(Vehicle vehicle, List<VehiclePhoto> photos);

  /// Sets the single availability range; both null clears it.
  Future<Result<void>> setAvailability(
    String vehicleId,
    DateTime? from,
    DateTime? to,
  );

  /// Writes [document] and, in the same batch, the car's new
  /// `docsValidUntil` and [status].
  Future<Result<void>> upsertDocument(
    VehicleDocument document, {
    required DateTime? docsValidUntil,
    required VehicleStatus status,
  });
}
