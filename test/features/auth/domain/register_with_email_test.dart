import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/enums/auth_provider_kind.dart';
import 'package:veloce/core/domain/enums/storage_bucket.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/auth/domain/entities/registration_outcome.dart';
import 'package:veloce/features/auth/domain/usecases/register_with_email.dart';
import 'package:veloce/features/auth/domain/usecases/submit_identity_document.dart';

import 'auth_fakes.dart';

void main() {
  late FakeAuthRepository auth;
  late FakeRegistrationStore store;
  late FakeMediaStorage media;
  late FakeVerification verification;
  late RegisterWithEmail register;

  setUp(() {
    auth = FakeAuthRepository();
    store = FakeRegistrationStore();
    media = FakeMediaStorage();
    verification = FakeVerification();
    register = RegisterWithEmail(
      auth: auth,
      store: store,
      submitDocument: SubmitIdentityDocument(
        storage: media,
        verification: verification,
      ),
      clock: const FixedClock(),
    );
  });

  Future<AppFailure> expectFailure(
    Future<Result<RegistrationOutcome>> run,
  ) async {
    final result = await run;
    expect(result, isA<Failure<RegistrationOutcome>>());
    return (result as Failure<RegistrationOutcome>).failure;
  }

  test(
    'renter registers: photo, auth user, profile, then verification mail',
    () async {
      final result = await register(aRegistration());

      final outcome = (result as Success<RegistrationOutcome>).value;
      expect(outcome.verificationEmailSent, isTrue);
      expect(auth.calls, ['create', 'mail']);
      expect(media.lastBucket, StorageBucket.userDocs);
      expect(store.written?.uid, 'uid-1');
      expect(store.written?.role, UserRole.renter);
      expect(store.written?.authProvider, AuthProviderKind.password);
      expect(store.written?.documentPhotoUrl, 'https://files/doc.jpg');
      expect(store.written?.licenceExpiry, DateTime(2030));
    },
  );

  test('owner registers with a National ID and no licence expiry', () async {
    await register(aRegistration(role: UserRole.owner));

    expect(store.written?.role, UserRole.owner);
    expect(store.written?.documentNumber, '1199880012345678');
    expect(store.written?.licenceExpiry, isNull);
  });

  test(
    'invalid input is rejected before anything is uploaded or created',
    () async {
      final failure = await expectFailure(
        register(aRegistration(dateOfBirth: DateTime(2015))),
      );

      expect(failure, isA<ValidationFailure>());
      expect(failure.message, contains('18'));
      expect(auth.calls, isEmpty);
      expect(media.lastBucket, isNull);
    },
  );

  test('a failed document check leaves no Auth user behind', () async {
    verification.documentResult = const Result.failure(
      ValidationFailure('We could not verify this document. Try again.'),
    );

    final failure = await expectFailure(register(aRegistration()));

    expect(failure.message, contains('verify this document'));
    expect(auth.calls, isEmpty);
    expect(media.deleted, ['https://files/doc.jpg']);
  });

  test(
    'email already in use surfaces the failure and discards the photo',
    () async {
      auth.createResult = const Result.failure(
        ConflictFailure('An account with this email already exists.'),
      );

      final failure = await expectFailure(register(aRegistration()));

      expect(failure, isA<ConflictFailure>());
      expect(store.written, isNull);
      expect(media.deleted, hasLength(1));
    },
  );

  test('a failed profile write rolls the Auth user and photo back', () async {
    store.writeResult = const Result.failure(PermissionFailure());

    final failure = await expectFailure(register(aRegistration()));

    expect(failure, isA<PermissionFailure>());
    expect(auth.calls, ['create', 'deleteUser']);
    expect(auth.user, isNull);
    expect(media.deleted, hasLength(1));
  });

  test('a mail failure does not undo the registration', () async {
    auth.mailResult = const Result.failure(NetworkFailure());

    final result = await register(aRegistration());

    expect(
      (result as Success<RegistrationOutcome>).value.verificationEmailSent,
      isFalse,
    );
    expect(store.written, isNotNull);
  });
}
