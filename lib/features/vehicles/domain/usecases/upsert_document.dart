import 'package:veloce/core/domain/entities/vehicle.dart';
import 'package:veloce/core/domain/entities/vehicle_document.dart';
import 'package:veloce/core/domain/enums/storage_bucket.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/domain/services/media_storage.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';

import '../entities/document_input.dart';
import '../repositories/vehicle_repository.dart';
import '../rules/document_rules.dart';
import '../rules/document_status_rules.dart';
import 'recompute_docs_valid_until.dart';
import 'verify_document.dart';

/// Adds or replaces one paper of a car: validates it, verifies it (simulated),
/// uploads the photo, then writes the document, the recomputed
/// `docsValidUntil` and the status in one batch.
class UpsertDocument {
  const UpsertDocument(
    this._vehicles,
    this._storage,
    this._verify,
    this._recompute,
    this._clock,
  );

  final VehicleRepository _vehicles;
  final MediaStorage _storage;
  final VerifyDocument _verify;
  final RecomputeDocsValidUntil _recompute;
  final Clock _clock;

  Future<Result<void>> call({
    required Vehicle vehicle,
    required List<VehicleDocument> current,
    required DocumentInput input,
  }) async {
    final now = _clock.now();
    final error =
        DocumentRules.plateMatches(input.plate, vehicle.plate) ??
        DocumentRules.expiry(input.expiry, now: now);
    if (error != null) return Result.failure(ValidationFailure(error));

    final existing = current
        .where((document) => document.kind == input.kind)
        .firstOrNull;
    final photo = input.photo;
    if (photo == null && existing == null) {
      return const Result.failure(
        ValidationFailure('Add a photo of the document.'),
      );
    }

    final verification = await _verify(input.number);
    if (verification is Failure<void>) {
      return Result.failure(verification.failure);
    }

    String photoUrl;
    String? uploaded;
    if (photo == null) {
      photoUrl = existing!.photoUrl;
    } else {
      final upload = await _storage.upload(
        bytes: photo.bytes,
        extension: photo.extension,
        bucket: StorageBucket.userDocs,
      );
      switch (upload) {
        case Failure(:final failure):
          return Result.failure(failure);
        case Success(:final value):
          photoUrl = value;
          uploaded = value;
      }
    }

    final document = VehicleDocument(
      kind: input.kind,
      vehicleId: vehicle.id,
      number: input.number.trim(),
      expiry: input.expiry!,
      photoUrl: photoUrl,
      verified: true,
    );
    final updated = [
      for (final other in current)
        if (other.kind != input.kind) other,
      document,
    ];
    final result = await _vehicles.upsertDocument(
      document,
      docsValidUntil: _recompute(updated),
      status: DocumentStatusRules.statusAfter(
        updated,
        current: vehicle.status,
        now: now,
      ),
    );
    if (result is Failure<void> && uploaded != null) {
      await _storage.delete(uploaded);
    }
    return result;
  }
}
