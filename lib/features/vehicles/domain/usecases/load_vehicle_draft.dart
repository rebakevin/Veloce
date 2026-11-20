import 'package:veloce/core/domain/entities/vehicle_photo.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';

import '../entities/wizard_draft.dart';
import '../repositories/vehicle_repository.dart';

/// Loads one of the owner's cars as a [WizardDraft] for edit mode.
///
/// Documents are not part of the edit flow (they have their own screen), so
/// the draft carries the listing fields and the car's existing photos only.
class LoadVehicleDraft {
  const LoadVehicleDraft(this._vehicles, this._session);

  final VehicleRepository _vehicles;
  final AuthSession _session;

  Future<Result<WizardDraft>> call(String vehicleId) async {
    final ownerId = _session.currentUserId;
    if (ownerId == null) {
      return const Result.failure(PermissionFailure('Sign in to edit a car.'));
    }
    final first =
        (await _vehicles.watchVehicle(vehicleId).take(1).toList()).firstOrNull;
    switch (first) {
      case null:
        return const Result.failure(NotFoundFailure());
      case Failure(:final failure):
        return Result.failure(failure);
      case Success(value: final vehicle):
        if (vehicle.ownerId != ownerId) {
          return const Result.failure(
            PermissionFailure('You can only edit your own cars.'),
          );
        }
        final photosResult = await _vehicles.photosOf(vehicleId);
        if (photosResult case Failure(:final failure)) {
          return Result.failure(failure);
        }
        final photos = [...(photosResult as Success<List<VehiclePhoto>>).value]
          ..sort((a, b) => a.order.compareTo(b.order));
        final primary = photos.indexWhere((photo) => photo.isPrimary);
        return Result.success(
          WizardDraft(
            vehicleId: vehicle.id,
            keptPhotos: photos,
            primaryIndex: primary < 0 ? 0 : primary,
            plate: vehicle.plate,
            make: vehicle.make,
            model: vehicle.model,
            year: vehicle.year,
            type: vehicle.type,
            neighbourhood: vehicle.neighbourhood,
            description: vehicle.description,
            transmission: vehicle.transmission,
            fuel: vehicle.fuel,
            seats: vehicle.seats,
            features: vehicle.features,
            dailyPrice: vehicle.dailyPrice,
            longRates: vehicle.longRates,
            cautionFee: vehicle.cautionFee,
            fuelRule: vehicle.fuelRule,
            smoking: vehicle.smoking,
            extras: vehicle.extras,
          ),
        );
    }
  }
}
