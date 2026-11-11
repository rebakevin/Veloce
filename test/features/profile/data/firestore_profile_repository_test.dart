import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/data/services/user_lookup.dart';
import 'package:veloce/core/domain/entities/document_photo.dart';
import 'package:veloce/core/domain/entities/payout_method.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/domain/services/atomic_write.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/domain/services/media_storage.dart';
import 'package:veloce/core/domain/services/verification_provider.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/profile/data/firestore_profile_repository.dart';
import 'package:veloce/features/profile/domain/entities/identity_submission.dart';
import 'package:veloce/features/profile/domain/entities/licence_submission.dart';
import 'package:veloce/features/profile/domain/entities/profile_update.dart';

import '../../auth/domain/auth_fakes.dart';

class _MockFirestore extends Mock implements FirebaseFirestore {}

class _MockWrites extends Mock implements AtomicWriteFactory {}

class _MockUsers extends Mock implements UserLookup {}

class _MockStorage extends Mock implements MediaStorage {}

class _MockVerification extends Mock implements VerificationProvider {}

class _Session implements AuthSession {
  _Session(this.currentUserId, this.role);

  @override
  final String? currentUserId;

  @override
  final UserRole? role;

  @override
  bool get isEmailVerified => true;

  @override
  Stream<void> get changes => const Stream.empty();
}

void main() {
  late _MockFirestore firestore;
  late _MockWrites writes;
  late _MockStorage storage;
  late _MockVerification verification;

  FirestoreProfileRepository repositoryFor(_Session session) =>
      FirestoreProfileRepository(
        firestore: firestore,
        writes: writes,
        users: _MockUsers(),
        storage: storage,
        verification: verification,
        session: session,
        clock: const FixedClock(),
      );

  void expectNoIo() {
    verifyZeroInteractions(firestore);
    verifyZeroInteractions(writes);
    verifyZeroInteractions(storage);
    verifyZeroInteractions(verification);
  }

  setUp(() {
    firestore = _MockFirestore();
    writes = _MockWrites();
    storage = _MockStorage();
    verification = _MockVerification();
  });

  test('an invalid MoMo number is rejected before any write', () async {
    final result = await repositoryFor(_Session('o1', UserRole.owner))
        .savePayout('0788123456');

    expect((result as Failure<PayoutMethod>).failure, isA<ValidationFailure>());
    expectNoIo();
  });

  test('a renter cannot save a payout number', () async {
    final result = await repositoryFor(_Session('r1', UserRole.renter))
        .savePayout('788123456');

    expect((result as Failure<PayoutMethod>).failure, isA<PermissionFailure>());
    expectNoIo();
  });

  test('profile edits are validated before the photo is uploaded', () async {
    final result = await repositoryFor(_Session('r1', UserRole.renter))
        .updateProfile(
          ProfileUpdate(
            name: '',
            phone: '0788123456',
            dateOfBirth: DateTime(1995),
            newPhoto: DocumentPhoto(
              bytes: Uint8List.fromList([1]),
              extension: 'jpg',
            ),
          ),
        );

    expect((result as Failure<void>).failure, isA<ValidationFailure>());
    expectNoIo();
  });

  test('an expired licence is rejected without verification', () async {
    final result = await repositoryFor(_Session('r1', UserRole.renter))
        .saveLicence(LicenceSubmission(number: 'DL-1', expiry: DateTime(2020)));

    expect(
      (result as Failure<dynamic>).failure.message,
      'This licence has expired.',
    );
    expectNoIo();
  });

  test('a malformed National ID is rejected for owners only', () async {
    final owner = await repositoryFor(_Session('o1', UserRole.owner))
        .replaceIdentity(const IdentitySubmission(nationalIdNumber: '12'));
    final renter = await repositoryFor(_Session('r1', UserRole.renter))
        .replaceIdentity(
          const IdentitySubmission(nationalIdNumber: '1199880012345678'),
        );

    expect((owner as Failure<dynamic>).failure, isA<ValidationFailure>());
    expect((renter as Failure<dynamic>).failure, isA<PermissionFailure>());
    expectNoIo();
  });

  test('signed-out callers get a permission failure', () async {
    final result = await repositoryFor(_Session(null, null)).getContact();

    expect((result as Failure<dynamic>).failure, isA<PermissionFailure>());
    expectNoIo();
  });
}
