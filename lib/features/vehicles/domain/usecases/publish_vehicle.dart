import 'package:veloce/core/domain/entities/document_photo.dart';
import 'package:veloce/core/domain/entities/vehicle.dart';
import 'package:veloce/core/domain/entities/vehicle_document.dart';
import 'package:veloce/core/domain/entities/vehicle_photo.dart';
import 'package:veloce/core/domain/enums/storage_bucket.dart';
import 'package:veloce/core/domain/enums/vehicle_status.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/domain/services/media_storage.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/auth/auth.dart';

import '../entities/publish_request.dart';
import '../entities/rules_pdf.dart';
import '../entities/wizard_draft.dart';
import '../entities/wizard_step.dart';
import '../repositories/vehicle_repository.dart';
import '../rules/document_rules.dart';
import '../rules/wizard_step_rules.dart';

class PublishVehicle {
  const PublishVehicle(
    this._vehicles,
    this._storage,
    this._session,
    this._clock,
  );

  final VehicleRepository _vehicles;
  final MediaStorage _storage;
  final AuthSession _session;
  final Clock _clock;

  Future<Result<String>> call(WizardDraft draft) async {
    final ownerId = _session.currentUserId;
    if (ownerId == null) {
      return const Result.failure(PermissionFailure('Sign in to list a car.'));
    }
    final emailFailure = EmailVerificationGate(_session).check();
    if (emailFailure != null) return Result.failure(emailFailure);
    final errors = {
      ...WizardStepRules.validate(WizardStep.review, draft, now: _clock.now()),
      ...WizardStepRules.validate(
        WizardStep.documents,
        draft,
        now: _clock.now(),
      ),
    };
    if (errors.isNotEmpty) {
      return Result.failure(ValidationFailure(errors.values.first));
    }

    final uploaded = <String>[];
    final photoUrls = <String>[];
    for (final photo in draft.photos) {
      final result = await _upload(photo, StorageBucket.carMedia);
      switch (result) {
        case Failure(:final failure):
          await _cleanUp(uploaded);
          return Result.failure(failure);
        case Success(:final value):
          uploaded.add(value);
          photoUrls.add(value);
      }
    }

    String? videoUrl;
    final video = draft.video;
    if (video != null) {
      final result = await _upload(video, StorageBucket.carMedia);
      switch (result) {
        case Failure(:final failure):
          await _cleanUp(uploaded);
          return Result.failure(failure);
        case Success(:final value):
          uploaded.add(value);
          videoUrl = value;
      }
    }

    String? rulesUrl;
    final rules = draft.rulesPdf;
    if (rules != null) {
      final result = await _storage.upload(
        bytes: rules.bytes,
        extension: RulesPdf.extension,
        bucket: StorageBucket.carMedia,
      );
      switch (result) {
        case Failure(:final failure):
          await _cleanUp(uploaded);
          return Result.failure(failure);
        case Success(:final value):
          uploaded.add(value);
          rulesUrl = value;
      }
    }

    final documents = <VehicleDocument>[];
    for (final entry in draft.documents.entries) {
      final photo = entry.value.photo;
      if (photo == null) continue;
      final result = await _upload(photo, StorageBucket.userDocs);
      switch (result) {
        case Failure(:final failure):
          await _cleanUp(uploaded);
          return Result.failure(failure);
        case Success(:final value):
          uploaded.add(value);
          documents.add(
            VehicleDocument(
              kind: entry.key,
              vehicleId: '',
              number: entry.value.number.trim(),
              expiry: entry.value.expiry!,
              photoUrl: value,
              verified: entry.value.verified,
            ),
          );
      }
    }

    final vehicle = Vehicle(
      id: '',
      ownerId: ownerId,
      plate: draft.plate.trim().toUpperCase(),
      make: draft.make.trim(),
      model: draft.model.trim(),
      year: draft.year!,
      type: draft.type!,
      transmission: draft.transmission!,
      fuel: draft.fuel!,
      seats: draft.seats!,
      features: draft.features,
      description: draft.description.trim(),
      dailyPrice: draft.dailyPrice!,
      longRates: draft.longRates,
      cautionFee: draft.cautionFee!,
      neighbourhood: draft.neighbourhood.trim(),
      fuelRule: draft.fuelRule.trim(),
      smoking: draft.smoking.trim(),
      extras: draft.extras,
      rulesFileUrl: rulesUrl,
      videoUrl: videoUrl,
      status: VehicleStatus.published,
      availableFrom: null,
      availableTo: null,
      docsValidUntil: DocumentRules.docsValidUntil(documents),
      ratingAvg: 0,
      ratingCount: 0,
      createdAt: _clock.now(),
    );
    final photos = [
      for (var i = 0; i < photoUrls.length; i++)
        VehiclePhoto(
          id: '',
          vehicleId: '',
          url: photoUrls[i],
          order: i,
          isPrimary: i == draft.primaryIndex,
        ),
    ];

    final result = await _vehicles.publish(
      PublishRequest(vehicle: vehicle, photos: photos, documents: documents),
    );
    if (result is Failure<String>) await _cleanUp(uploaded);
    return result;
  }

  Future<Result<String>> _upload(DocumentPhoto photo, StorageBucket bucket) {
    return _storage.upload(
      bytes: photo.bytes,
      extension: photo.extension,
      bucket: bucket,
    );
  }

  Future<void> _cleanUp(List<String> urls) async {
    for (final url in urls) {
      await _storage.delete(url);
    }
  }
}
