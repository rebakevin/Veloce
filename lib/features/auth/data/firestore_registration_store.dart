import 'package:veloce/core/constants/firestore_paths.dart';
import 'package:veloce/core/data/models/contact_model.dart';
import 'package:veloce/core/data/models/licence_model.dart';
import 'package:veloce/core/data/models/owner_identity_model.dart';
import 'package:veloce/core/data/models/user_account_model.dart';
import 'package:veloce/core/data/services/failure_mapper.dart';
import 'package:veloce/core/data/services/firebase_auth_session.dart';
import 'package:veloce/core/data/services/user_lookup.dart';
import 'package:veloce/core/domain/entities/contact.dart';
import 'package:veloce/core/domain/entities/licence.dart';
import 'package:veloce/core/domain/entities/owner_identity.dart';
import 'package:veloce/core/domain/entities/user_account.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/domain/services/atomic_write.dart';
import 'package:veloce/core/domain/services/audit_logger.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';

import '../domain/entities/new_profile.dart';
import '../domain/repositories/registration_store.dart';

/// [RegistrationStore] on Firestore. The profile, its private documents and the
/// registration audit entry go in one [AtomicWrite] (W1).
class FirestoreRegistrationStore implements RegistrationStore {
  const FirestoreRegistrationStore({
    required this._writes,
    required this._audit,
    required this._users,
    required this._session,
    required this._clock,
  });

  static const Duration _timeout = Duration(seconds: 20);

  final AtomicWriteFactory _writes;
  final AuditLogger _audit;
  final UserLookup _users;
  final FirebaseAuthSession _session;
  final Clock _clock;

  @override
  Future<Result<UserAccount?>> findProfile(String uid) async {
    final result = await _users.byId(uid);
    return switch (result) {
      Success(:final value) => Result.success(value),
      Failure(failure: NotFoundFailure()) => const Result.success(null),
      Failure(:final failure) => Result.failure(failure),
    };
  }

  @override
  Future<Result<void>> createProfile(NewProfile profile) async {
    try {
      final write = _writes.begin();
      final uid = profile.uid;
      write.set(
        FirestorePaths.user(uid),
        UserAccountModel.toMap(
          UserAccount(
            id: uid,
            role: profile.role,
            name: profile.name,
            photoUrl: null,
            verified: true,
            ratingAvg: 0,
            ratingCount: 0,
            completedCount: 0,
            createdAt: _clock.now(),
          ),
        ),
      );
      write.set(
        FirestorePaths.userPrivate(uid, FirestorePaths.contactDoc),
        ContactModel.toMap(
          Contact(
            userId: uid,
            email: profile.email,
            phone: profile.phone,
            dateOfBirth: profile.dateOfBirth,
            authProvider: profile.authProvider,
          ),
        ),
      );
      _addDocument(write, profile);
      _audit.record(
        write,
        actorId: uid,
        entityType: 'user',
        entityId: uid,
        oldState: null,
        newState: 'registered',
      );
      await write.commit().timeout(_timeout);
      // The role was unknown when sign-in fired; tell the session now.
      await _session.refresh();
      return const Result.success(null);
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }

  void _addDocument(AtomicWrite write, NewProfile profile) {
    final uid = profile.uid;
    switch (profile.role) {
      case UserRole.renter:
        write.set(
          FirestorePaths.userPrivate(uid, FirestorePaths.licenceDoc),
          LicenceModel.toMap(
            Licence(
              userId: uid,
              number: profile.documentNumber,
              expiry: profile.licenceExpiry!,
              photoUrl: profile.documentPhotoUrl,
              active: true,
            ),
          ),
        );
      case UserRole.owner:
        write.set(
          FirestorePaths.userPrivate(uid, FirestorePaths.identityDoc),
          OwnerIdentityModel.toMap(
            OwnerIdentity(
              userId: uid,
              nationalIdNumber: profile.documentNumber,
              photoUrl: profile.documentPhotoUrl,
            ),
          ),
        );
    }
  }
}
