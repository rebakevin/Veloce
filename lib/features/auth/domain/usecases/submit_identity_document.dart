import 'package:veloce/core/domain/enums/storage_bucket.dart';
import 'package:veloce/core/domain/services/media_storage.dart';
import 'package:veloce/core/domain/services/verification_provider.dart';
import 'package:veloce/core/error/result.dart';

import '../entities/registration_document.dart';

/// Uploads a sign-up document photo to `user-docs` and runs the simulated
/// document check on it. Returns the photo URL.
class SubmitIdentityDocument {
  const SubmitIdentityDocument({
    required this._storage,
    required this._verification,
  });

  final MediaStorage _storage;
  final VerificationProvider _verification;

  Future<Result<String>> call(RegistrationDocument document) async {
    final uploaded = await _storage.upload(
      bytes: document.photoBytes,
      extension: document.photoExtension,
      bucket: StorageBucket.userDocs,
    );
    if (uploaded case Failure(:final failure)) return Result.failure(failure);
    final url = (uploaded as Success<String>).value;

    final verified = await _verification.verifyDocument(
      documentNumber: document.number,
      photoUrl: url,
    );
    if (verified case Failure(:final failure)) {
      await discard(url);
      return Result.failure(failure);
    }
    return Result.success(url);
  }

  /// Best effort removal of an uploaded photo after a later step failed.
  Future<void> discard(String url) async {
    await _storage.delete(url);
  }
}
