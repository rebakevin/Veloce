import 'dart:async';
import 'dart:typed_data';

import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/domain/entities/user_account.dart';
import 'package:veloce/core/domain/enums/auth_provider_kind.dart';
import 'package:veloce/core/domain/enums/storage_bucket.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/domain/services/media_storage.dart';
import 'package:veloce/core/domain/services/verification_provider.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/auth/domain/entities/auth_user.dart';
import 'package:veloce/features/auth/domain/entities/linked_account.dart';
import 'package:veloce/features/auth/domain/entities/new_profile.dart';
import 'package:veloce/features/auth/domain/entities/registration_document.dart';
import 'package:veloce/features/auth/domain/entities/registration_input.dart';
import 'package:veloce/features/auth/domain/repositories/auth_repository.dart';
import 'package:veloce/features/auth/domain/repositories/linked_account_store.dart';
import 'package:veloce/features/auth/domain/repositories/registration_store.dart';
import 'package:veloce/features/auth/domain/usecases/link_current_account.dart';

import '../../../support/builders.dart';

class FixedClock implements Clock {
  const FixedClock();

  @override
  DateTime now() => testNow;
}

AuthUser anAuthUser({
  String uid = 'uid-1',
  AuthProviderKind provider = AuthProviderKind.password,
}) => AuthUser(
  uid: uid,
  email: '$uid@example.com',
  emailVerified: provider == AuthProviderKind.google,
  displayName: 'Aline Uwase',
  provider: provider,
);

LinkedAccount aLinkedAccount() => const LinkedAccount(
  uid: 'uid-1',
  email: 'uid-1@example.com',
  name: 'Aline Uwase',
  role: UserRole.renter,
  authType: AuthProviderKind.password,
);

class MockLinkCurrentAccount extends Mock implements LinkCurrentAccount {}

/// Makes [link] succeed for both call shapes: with a password (email
/// accounts) and without one (Google accounts).
void stubLinkSucceeds(MockLinkCurrentAccount link) {
  when(() => link(password: any(named: 'password')))
      .thenAnswer((_) async => Result.success(aLinkedAccount()));
  when(() => link()).thenAnswer((_) async => Result.success(aLinkedAccount()));
}

void verifyNoLink(MockLinkCurrentAccount link) {
  verifyNever(() => link(password: any(named: 'password')));
  verifyNever(() => link());
}

RegistrationInput aRegistration({
  UserRole role = UserRole.renter,
  String email = 'aline@example.com',
  String password = 'secret123',
  String phone = '0788123456',
  DateTime? dateOfBirth,
}) => RegistrationInput(
  role: role,
  name: 'Aline Uwase',
  phone: phone,
  email: email,
  password: password,
  dateOfBirth: dateOfBirth ?? DateTime(1995, 5, 5),
  document: RegistrationDocument(
    number: role == UserRole.renter ? 'DL-12345' : '1199880012345678',
    licenceExpiry: role == UserRole.renter ? DateTime(2030) : null,
    photoBytes: Uint8List.fromList([1, 2, 3]),
    photoExtension: 'jpg',
  ),
);

/// Records calls and replays configured results.
class FakeAuthRepository implements AuthRepository {
  AuthUser? user;
  Result<AuthUser>? createResult;
  Result<AuthUser>? signInResult;
  Result<AuthUser> googleResult = Result.success(
    anAuthUser(provider: AuthProviderKind.google),
  );
  Result<AuthUser?> silentGoogleResult = const Result.success(null);
  Result<void> mailResult = const Result.success(null);
  final List<String> calls = [];

  @override
  AuthUser? get currentUser => user;

  @override
  Stream<AuthUser?> get userChanges => const Stream.empty();

  @override
  Future<Result<AuthUser>> createEmailUser({
    required String email,
    required String password,
    required String displayName,
  }) async {
    calls.add('create');
    final result = createResult ?? Result.success(anAuthUser());
    if (result case Success(:final value)) user = value;
    return result;
  }

  @override
  Future<Result<AuthUser>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    calls.add('signInEmail:$email:$password');
    final result = signInResult ?? Result.success(anAuthUser());
    if (result case Success(:final value)) user = value;
    return result;
  }

  @override
  Future<Result<AuthUser>> signInWithGoogle() async {
    calls.add('google');
    if (googleResult case Success(:final value)) user = value;
    return googleResult;
  }

  @override
  Future<Result<AuthUser?>> signInWithGoogleSilently() async {
    calls.add('googleSilent');
    if (silentGoogleResult case Success(:final value)) user = value;
    return silentGoogleResult;
  }

  @override
  Future<Result<void>> sendPasswordReset(String email) async {
    calls.add('reset:$email');
    return const Result.success(null);
  }

  @override
  Future<Result<void>> sendEmailVerification() async {
    calls.add('mail');
    return mailResult;
  }

  @override
  Future<Result<AuthUser>> reloadUser() async =>
      Result.success(user ?? anAuthUser());

  Result<void> reauthResult = const Result.success(null);
  Result<void> deleteResult = const Result.success(null);

  @override
  Future<Result<void>> reauthenticate({required String password}) async {
    calls.add('reauth:$password');
    return reauthResult;
  }

  @override
  Future<Result<void>> deleteCurrentUser() async {
    calls.add('deleteUser');
    if (deleteResult is Success) user = null;
    return deleteResult;
  }

  @override
  Future<Result<void>> signOut() async {
    calls.add('signOut');
    user = null;
    return const Result.success(null);
  }

  @override
  Future<Result<void>> suspendSession() async {
    calls.add('suspend');
    user = null;
    return const Result.success(null);
  }
}

class FakeRegistrationStore implements RegistrationStore {
  UserAccount? profile;
  Result<void> writeResult = const Result.success(null);
  NewProfile? written;

  @override
  Future<Result<UserAccount?>> findProfile(String uid) async =>
      Result.success(profile);

  @override
  Future<Result<void>> createProfile(NewProfile profile) async {
    written = profile;
    return writeResult;
  }
}

class FakeMediaStorage implements MediaStorage {
  Result<String> uploadResult = const Result.success('https://files/doc.jpg');
  StorageBucket? lastBucket;
  final List<String> deleted = [];

  @override
  Future<Result<String>> upload({
    required Uint8List bytes,
    required String extension,
    required StorageBucket bucket,
  }) async {
    lastBucket = bucket;
    return uploadResult;
  }

  @override
  Future<Result<void>> delete(String url) async {
    deleted.add(url);
    return const Result.success(null);
  }
}

class FakeVerification implements VerificationProvider {
  Result<void> documentResult = const Result.success(null);
  int documentChecks = 0;

  @override
  Future<Result<OtpChallenge>> sendOtp(String phone) async =>
      Result.success(OtpChallenge(phone: phone, code: '123456'));

  @override
  Future<Result<void>> confirmOtp({
    required OtpChallenge challenge,
    required String code,
  }) async => const Result.success(null);

  @override
  Future<Result<void>> verifyDocument({
    required String documentNumber,
    required String photoUrl,
  }) async {
    documentChecks++;
    return documentResult;
  }
}

class MemoryLinkedAccountStore implements LinkedAccountStore {
  final Map<String, LinkedAccount> accounts = {};
  final Map<String, String> passwords = {};

  @override
  Future<Result<List<LinkedAccount>>> list() async =>
      Result.success(accounts.values.toList());

  @override
  Future<Result<void>> save(LinkedAccount account, {String? password}) async {
    accounts[account.uid] = account;
    if (password == null) {
      passwords.remove(account.uid);
    } else {
      passwords[account.uid] = password;
    }
    return const Result.success(null);
  }

  @override
  Future<Result<String?>> passwordOf(String uid) async =>
      Result.success(passwords[uid]);

  @override
  Future<Result<void>> remove(String uid) async {
    accounts.remove(uid);
    passwords.remove(uid);
    return const Result.success(null);
  }
}

const networkDown = Result<AuthUser>.failure(NetworkFailure());
