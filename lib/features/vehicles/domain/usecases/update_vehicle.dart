import 'package:veloce/core/domain/entities/document_photo.dart';
import 'package:veloce/core/domain/entities/vehicle_photo.dart';
import 'package:veloce/core/domain/enums/storage_bucket.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/domain/services/media_storage.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';

import '../entities/wizard_draft.dart';
import '../entities/wizard_step.dart';
import '../repositories/vehicle_repository.dart';
import '../rules/wizard_step_rules.dart';

/// Saves an edited listing. Status, availability, documents and
/// `docsValidUntil` are kept as they are: the documents step is not part of
/// edit mode.
class UpdateVehicle {
  const UpdateVehicle(this._vehicles, this._storage, this._session);

  final VehicleRepository _vehicles;
  final MediaStorage _storage;
  final AuthSession _session;

  Future<Result<void>> call(WizardDraft draft) async {
    final ownerId = _session.currentUserId;
    final vehicleId = draft.vehicleId;
    if (ownerId == null || vehicleId == null) {
      return const Result.failure(PermissionFailure('Sign in to edit a car.'));
    }
    final errors = WizardStepRules.validate(WizardStep.review, draft);
    if (errors.isNotEmpty) {
      return Result.failure(ValidationFailure(errors.values.first));
    }

    final current =
        (await _vehicles.watchVehicle(vehicleId).take(1).toList()).firstOrNull;
    switch (current) {
      case null:
        return const Result.failure(NotFoundFailure());
      case Failure(:final failure):
        return Result.failure(failure);
      case Success(value: final existing):
        if (existing.ownerId != ownerId) {
          return const Result.failure(
            PermissionFailure('You can only edit your own cars.'),
          );
        }
        final oldPhotos = await _vehicles.photosOf(vehicleId);
        if (oldPhotos case Failure(:final failure)) {
          return Result.failure(failure);
        }

        final uploaded = <String>[];
        for (final photo in draft.photos) {
          final result = await _upload(photo);
          switch (result) {
            case Failure(:final failure):
              await _delete(uploaded);
              return Result.failure(failure);
            case Success(:final value):
              uploaded.add(value);
          }
        }

        final urls = [for (final p in draft.keptPhotos) p.url, ...uploaded];
        final photos = [
          for (var i = 0; i < urls.length; i++)
            VehiclePhoto(
              id: '',
              vehicleId: vehicleId,
              url: urls[i],
              order: i,
              isPrimary: i == draft.primaryIndex,
            ),
        ];
        final vehicle = existing.copyWith(
          plate: draft.plate.trim().toUpperCase(),
          make: draft.make.trim(),
          model: draft.model.trim(),
          year: draft.year,
          type: draft.type,
          transmission: draft.transmission,
          fuel: draft.fuel,
          seats: draft.seats,
          features: draft.features,
          description: draft.description.trim(),
          dailyPrice: draft.dailyPrice,
          longRates: draft.longRates,
          cautionFee: draft.cautionFee,
          neighbourhood: draft.neighbourhood.trim(),
          fuelRule: draft.fuelRule.trim(),
          smoking: draft.smoking.trim(),
          extras: draft.extras,
        );

        final result = await _vehicles.update(vehicle, photos);
        switch (result) {
          case Failure():
            await _delete(uploaded);
          case Success():
            final kept = urls.toSet();
            await _delete([
              for (final old
                  in (oldPhotos as Success<List<VehiclePhoto>>).value)
                if (!kept.contains(old.url)) old.url,
            ]);
        }
        return result;
    }
  }

  Future<Result<String>> _upload(DocumentPhoto photo) {
    return _storage.upload(
      bytes: photo.bytes,
      extension: photo.extension,
      bucket: StorageBucket.carMedia,
    );
  }

  Future<void> _delete(List<String> urls) async {
    for (final url in urls) {
      await _storage.delete(url);
    }
  }
}
