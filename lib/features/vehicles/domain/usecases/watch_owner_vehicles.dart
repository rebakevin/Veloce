import 'package:veloce/core/domain/entities/vehicle.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';

import '../repositories/vehicle_repository.dart';

class WatchOwnerVehicles {
  const WatchOwnerVehicles(this._vehicles, this._session);

  final VehicleRepository _vehicles;
  final AuthSession _session;

  Stream<Result<List<Vehicle>>> call() {
    final ownerId = _session.currentUserId;
    if (ownerId == null) {
      return Stream.value(
        const Result<List<Vehicle>>.failure(
          PermissionFailure('Sign in to see your cars.'),
        ),
      );
    }
    return _vehicles.watchOwnerVehicles(ownerId);
  }
}