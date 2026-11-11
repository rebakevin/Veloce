import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veloce/core/constants/firestore_fields.dart';
import 'package:veloce/core/constants/firestore_paths.dart';
import 'package:veloce/core/data/models/contact_model.dart';
import 'package:veloce/core/data/models/licence_model.dart';
import 'package:veloce/core/data/models/owner_identity_model.dart';
import 'package:veloce/core/data/models/payout_method_model.dart';
import 'package:veloce/core/data/services/failure_mapper.dart';
import 'package:veloce/core/data/services/user_lookup.dart';
import 'package:veloce/core/domain/entities/contact.dart';
import 'package:veloce/core/domain/entities/document_photo.dart';
import 'package:veloce/core/domain/entities/licence.dart';
import 'package:veloce/core/domain/entities/owner_identity.dart';
import 'package:veloce/core/domain/entities/payout_method.dart';
import 'package:veloce/core/domain/entities/user_account.dart';
import 'package:veloce/core/domain/enums/storage_bucket.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/domain/services/atomic_write.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/domain/services/media_storage.dart';
import 'package:veloce/core/domain/services/verification_provider.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/core/validation/validators.dart';

import '../domain/entities/identity_submission.dart';
import '../domain/entities/licence_submission.dart';
import '../domain/entities/profile_update.dart';
import '../domain/entities/public_profile.dart';
import '../domain/repositories/profile_repository.dart';

/// [ProfileRepository] on Firestore and [MediaStorage]. Photos (avatar and
/// documents) are uploaded to the `user-docs` bucket, which TECHNICAL.md §7
/// names for profile photos. Replaced files are not deleted: the anon role has
/// no delete policy, so replacing means a new path.
class FirestoreProfileRepository implements ProfileRepository {
  const FirestoreProfileRepository({
    required this._firestore,
    required this._writes,
    required this._users,
    required this._storage,
    required this._verification,
    required this._session,
    required this._clock,
  });

  static const Duration _timeout = Duration(seconds: 20);
  static const StorageBucket _bucket = StorageBucket.userDocs;

  final FirebaseFirestore _firestore;
  final AtomicWriteFactory _writes;
  final UserLookup _users;
  final MediaStorage _storage;
  final VerificationProvider _verification;
  final AuthSession _session;
  final Clock _clock;

  @override
  Future<Result<UserAccount>> getProfile() => _ownThen(_users.byId);

  @override
  Stream<Result<UserAccount>> watchProfile() {
    final uid = _session.currentUserId;
    if (uid == null) return Stream.value(_signedOut());
    return _users.watch(uid);
  }

  @override
  Future<Result<Contact>> getContact() {
    return _ownThen((uid) async {
      final data = await _readPrivate(uid, FirestorePaths.contactDoc);
      return switch (data) {
        Success(:final value) when value == null => const Result.failure(
          NotFoundFailure(),
        ),
        Success(:final value) => _parse(
          () => ContactModel.fromMap(uid, value!),
        ),
        Failure(:final failure) => Result.failure(failure),
      };
    });
  }

  @override
  Future<Result<void>> updateProfile(ProfileUpdate update) {
    return _ownThen((uid) async {
      final problem = update.validate(now: _clock.now());
      if (problem != null) return Result.failure(ValidationFailure(problem));

      String? photoUrl;
      final photo = update.newPhoto;
      if (photo != null) {
        final uploaded = await _upload(photo);
        if (uploaded case Failure(:final failure)) {
          return Result.failure(failure);
        }
        photoUrl = (uploaded as Success<String>).value;
      }

      try {
        final write = _writes.begin();
        write.update(FirestorePaths.user(uid), {
          FirestoreFields.name: update.name.trim(),
          // ignore: use_null_aware_elements
          if (photoUrl != null) FirestoreFields.photoUrl: photoUrl,
        });
        write.update(
          FirestorePaths.userPrivate(uid, FirestorePaths.contactDoc),
          {
            FirestoreFields.phone: update.phone.trim(),
            FirestoreFields.dateOfBirth: Timestamp.fromDate(update.dateOfBirth),
          },
        );
        await write.commit().timeout(_timeout);
        _users.clear();
        return const Result.success(null);
      } on Object catch (error, stackTrace) {
        return Result.failure(mapToFailure(error, stackTrace));
      }
    });
  }

  @override
  Future<Result<Licence?>> getLicence() {
    return _ownThen((uid) async {
      final data = await _readPrivate(uid, FirestorePaths.licenceDoc);
      return switch (data) {
        Success(:final value) when value == null => const Result.success(null),
        Success(:final value) => _parse<Licence?>(
          () => LicenceModel.fromMap(uid, value!),
        ),
        Failure(:final failure) => Result.failure(failure),
      };
    });
  }

  @override
  Future<Result<Licence>> saveLicence(LicenceSubmission submission) {
    return _ownThen((uid) async {
      final denied = _requireRole(UserRole.renter, 'renters');
      if (denied != null) return Result.failure(denied);
      final problem = submission.validate(now: _clock.now());
      if (problem != null) return Result.failure(ValidationFailure(problem));

      final existing = await getLicence();
      if (existing case Failure(:final failure)) return Result.failure(failure);
      final photoUrl = await _photoUrlFor(
        submission.photo,
        keep: (existing as Success<Licence?>).value?.photoUrl,
      );
      if (photoUrl case Failure(:final failure)) return Result.failure(failure);

      final licence = Licence(
        userId: uid,
        number: submission.number.trim(),
        expiry: submission.expiry,
        photoUrl: (photoUrl as Success<String>).value,
        active: true,
      );
      final verified = await _verification.verifyDocument(
        documentNumber: licence.number,
        photoUrl: licence.photoUrl,
      );
      if (verified case Failure(:final failure)) {
        return Result.failure(failure);
      }
      final written = await _writePrivate(
        uid,
        FirestorePaths.licenceDoc,
        LicenceModel.toMap(licence),
      );
      return switch (written) {
        Success() => Result.success(licence),
        Failure(:final failure) => Result.failure(failure),
      };
    });
  }

  @override
  Future<Result<OwnerIdentity?>> getIdentity() {
    return _ownThen((uid) async {
      final data = await _readPrivate(uid, FirestorePaths.identityDoc);
      return switch (data) {
        Success(:final value) when value == null => const Result.success(null),
        Success(:final value) => _parse<OwnerIdentity?>(
          () => OwnerIdentityModel.fromMap(uid, value!),
        ),
        Failure(:final failure) => Result.failure(failure),
      };
    });
  }

  @override
  Future<Result<OwnerIdentity>> replaceIdentity(IdentitySubmission submission) {
    return _ownThen((uid) async {
      final denied = _requireRole(UserRole.owner, 'car owners');
      if (denied != null) return Result.failure(denied);
      final problem = submission.validate();
      if (problem != null) return Result.failure(ValidationFailure(problem));

      final existing = await getIdentity();
      if (existing case Failure(:final failure)) return Result.failure(failure);
      final photoUrl = await _photoUrlFor(
        submission.photo,
        keep: (existing as Success<OwnerIdentity?>).value?.photoUrl,
      );
      if (photoUrl case Failure(:final failure)) return Result.failure(failure);

      final identity = OwnerIdentity(
        userId: uid,
        nationalIdNumber: submission.nationalIdNumber.trim(),
        photoUrl: (photoUrl as Success<String>).value,
      );
      final verified = await _verification.verifyDocument(
        documentNumber: identity.nationalIdNumber,
        photoUrl: identity.photoUrl,
      );
      if (verified case Failure(:final failure)) {
        return Result.failure(failure);
      }
      final written = await _writePrivate(
        uid,
        FirestorePaths.identityDoc,
        OwnerIdentityModel.toMap(identity),
      );
      return switch (written) {
        Success() => Result.success(identity),
        Failure(:final failure) => Result.failure(failure),
      };
    });
  }

  @override
  Future<Result<PayoutMethod?>> getPayout() {
    return _ownThen((uid) async {
      final data = await _readPrivate(uid, FirestorePaths.payoutDoc);
      return switch (data) {
        Success(:final value) when value == null => const Result.success(null),
        Success(:final value) => _parse<PayoutMethod?>(
          () => PayoutMethodModel.fromMap(uid, value!),
        ),
        Failure(:final failure) => Result.failure(failure),
      };
    });
  }

  @override
  Future<Result<PayoutMethod>> savePayout(String momoNumber) {
    return _ownThen((uid) async {
      final denied = _requireRole(UserRole.owner, 'car owners');
      if (denied != null) return Result.failure(denied);
      final problem = Validators.momoNumber(momoNumber);
      if (problem != null) return Result.failure(ValidationFailure(problem));

      final payout = PayoutMethod(userId: uid, momoNumber: momoNumber.trim());
      final written = await _writePrivate(
        uid,
        FirestorePaths.payoutDoc,
        PayoutMethodModel.toMap(payout),
      );
      return switch (written) {
        Success() => Result.success(payout),
        Failure(:final failure) => Result.failure(failure),
      };
    });
  }

  @override
  Future<Result<PublicProfile>> getPublicProfile(String userId) async {
    final result = await _users.byId(userId);
    return switch (result) {
      Success(:final value) => Result.success(
        PublicProfile(
          userId: value.id,
          name: value.name,
          photoUrl: value.photoUrl,
          ratingAvg: value.ratingAvg,
          ratingCount: value.ratingCount,
          completedCount: value.completedCount,
        ),
      ),
      Failure(:final failure) => Result.failure(failure),
    };
  }

  /// Runs [action] for the signed-in user, or fails when nobody is.
  Future<Result<T>> _ownThen<T>(Future<Result<T>> Function(String uid) action) {
    final uid = _session.currentUserId;
    if (uid == null) return Future.value(_signedOut());
    return action(uid);
  }

  Result<T> _signedOut<T>() =>
      const Result.failure(PermissionFailure('Sign in to see your profile.'));

  PermissionFailure? _requireRole(UserRole expected, String who) {
    final role = _session.role;
    if (role == null || role == expected) return null;
    return PermissionFailure('Only $who can do this.');
  }

  Future<Result<String>> _upload(DocumentPhoto photo) {
    if (photo.isEmpty) {
      return Future.value(
        const Result.failure(
          ValidationFailure('Add a photo of your document.'),
        ),
      );
    }
    return _storage.upload(
      bytes: photo.bytes,
      extension: photo.extension,
      bucket: _bucket,
    );
  }

  /// Uploads [photo], or returns [keep] when no new photo is given.
  Future<Result<String>> _photoUrlFor(DocumentPhoto? photo, {String? keep}) {
    if (photo != null) return _upload(photo);
    if (keep != null) return Future.value(Result.success(keep));
    return Future.value(
      const Result.failure(ValidationFailure('Add a photo of your document.')),
    );
  }

  Future<Result<Map<String, dynamic>?>> _readPrivate(
    String uid,
    String doc,
  ) async {
    try {
      final snapshot = await _firestore
          .doc(FirestorePaths.userPrivate(uid, doc))
          .get()
          .timeout(_timeout);
      return Result.success(snapshot.data());
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }

  Future<Result<void>> _writePrivate(
    String uid,
    String doc,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore
          .doc(FirestorePaths.userPrivate(uid, doc))
          .set(data)
          .timeout(_timeout);
      return const Result.success(null);
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }

  Result<T> _parse<T>(T Function() build) {
    try {
      return Result.success(build());
    } on FormatException catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }
}
