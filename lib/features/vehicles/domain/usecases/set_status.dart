import 'package:veloce/core/domain/entities/vehicle.dart';
import 'package:veloce/core/domain/enums/vehicle_status.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';

import '../repositories/vehicle_repository.dart';

class SetStatus {
  const SetStatus(this._vehicles, this._clock);

  final VehicleRepository _vehicles;
  final Clock _clock;

  Future<Result<void>> call(Vehicle vehicle, VehicleStatus status) {
    if (status == VehicleStatus.published && !_documentsValid(vehicle)) {
      return Future.value(
        const Result.failure(
          ConflictFailure(
            'Update the expired documents before resuming this car.',
          ),
        ),
      );
    }
    return _vehicles.setStatus(vehicle.id, status);
  }

  bool _documentsValid(Vehicle vehicle) {
    final validUntil = vehicle.docsValidUntil;
    return validUntil != null && validUntil.isAfter(_clock.now());
  }
}
