import 'package:veloce/core/domain/entities/booking.dart';
import 'package:veloce/core/domain/entities/vehicle.dart';
import 'package:veloce/core/domain/enums/vehicle_status.dart';
import 'package:veloce/core/error/result.dart';

abstract interface class VehicleRepository {
  Stream<List<Vehicle>> watchOwnerVehicles(String ownerId);

  Future<Result<List<Booking>>> bookingsOf(String vehicleId);

  Future<Result<void>> setStatus(String vehicleId, VehicleStatus status);

  Future<Result<void>> remove(String vehicleId);
}
