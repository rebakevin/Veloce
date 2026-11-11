import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/enums/auth_provider_kind.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/auth/domain/entities/linked_account.dart';
import 'package:veloce/features/auth/domain/entities/switch_outcome.dart';
import 'package:veloce/features/auth/domain/usecases/link_current_account.dart';
import 'package:veloce/features/auth/domain/usecases/list_linked_accounts.dart';
import 'package:veloce/features/auth/domain/usecases/remove_linked_account.dart';
import 'package:veloce/features/auth/domain/usecases/switch_account.dart';

import '../../../support/builders.dart';
import 'auth_fakes.dart';

void main() {
  late FakeAuthRepository auth;
  late FakeRegistrationStore profiles;
  late MemoryLinkedAccountStore store;
  late SwitchAccount switchAccount;

  const emailAccount = LinkedAccount(
    uid: 'owner-1',
    email: 'owner-1@example.com',
    name: 'Owner One',
    role: UserRole.owner,
    authType: AuthProviderKind.password,
  );
  const googleAccount = LinkedAccount(
    uid: 'g-1',
    email: 'g-1@example.com',
    name: 'Gina',
    role: UserRole.renter,
    authType: AuthProviderKind.google,
  );

  setUp(() {
    auth = FakeAuthRepository()..user = anAuthUser(uid: 'renter-1');
    profiles = FakeRegistrationStore();
    store = MemoryLinkedAccountStore()
      ..accounts[emailAccount.uid] = emailAccount
      ..passwords[emailAccount.uid] = 'secret123'
      ..accounts[googleAccount.uid] = googleAccount;
    switchAccount = SwitchAccount(auth: auth, store: store);
  });

  Future<SwitchOutcome> outcomeOf(String uid) async =>
      ((await switchAccount(uid)) as Success<SwitchOutcome>).value;

  test(
    'email account: suspends the session and signs in with the stored password',
    () async {
      auth.signInResult = Result.success(anAuthUser(uid: 'owner-1'));

      expect(await outcomeOf('owner-1'), SwitchOutcome.switched);
      expect(auth.calls, [
        'suspend',
        'signInEmail:owner-1@example.com:secret123',
      ]);
      expect(store.accounts, hasLength(2));
    },
  );

  test('a changed password asks the user to sign in again', () async {
    auth.signInResult = const Result.failure(
      ValidationFailure('Wrong email or password.'),
    );

    expect(await outcomeOf('owner-1'), SwitchOutcome.signInRequired);
  });

  test('a missing stored password asks the user to sign in again', () async {
    store.passwords.clear();

    expect(await outcomeOf('owner-1'), SwitchOutcome.signInRequired);
    expect(auth.calls, ['suspend']);
  });

  test('a network error is a failure, not a sign-in prompt', () async {
    auth.signInResult = const Result.failure(NetworkFailure());

    final result = await switchAccount('owner-1');

    expect((result as Failure<SwitchOutcome>).failure, isA<NetworkFailure>());
  });

  test('Google account: silent sign-in switches without UI', () async {
    auth.silentGoogleResult = Result.success(
      anAuthUser(uid: 'g-1', provider: AuthProviderKind.google),
    );

    expect(await outcomeOf('g-1'), SwitchOutcome.switched);
    expect(auth.calls, ['suspend', 'googleSilent']);
  });

  test(
    'Google needing interaction, or another account, requires sign-in',
    () async {
      expect(await outcomeOf('g-1'), SwitchOutcome.signInRequired);

      auth.silentGoogleResult = Result.success(
        anAuthUser(uid: 'someone-else', provider: AuthProviderKind.google),
      );
      expect(await outcomeOf('g-1'), SwitchOutcome.signInRequired);
      expect(auth.user, isNull);
    },
  );

  test(
    'unknown account is a not-found failure and signs nothing out',
    () async {
      final result = await switchAccount('ghost');

      expect(
        (result as Failure<SwitchOutcome>).failure,
        isA<NotFoundFailure>(),
      );
      expect(auth.calls, isEmpty);
    },
  );

  test('removing drops the account and its password only', () async {
    await RemoveLinkedAccount(store)('owner-1');

    final listed = await ListLinkedAccounts(store)();
    expect((listed as Success<List<LinkedAccount>>).value, [googleAccount]);
    expect(store.passwords, isEmpty);
  });

  group('LinkCurrentAccount', () {
    late LinkCurrentAccount link;

    setUp(() {
      link = LinkCurrentAccount(auth: auth, profiles: profiles, store: store);
      profiles.profile = aUser();
    });

    test('email account is stored with its password', () async {
      final result = await link(password: 'pw-12345');

      final account = (result as Success<LinkedAccount>).value;
      expect(account.name, 'Aline Uwase');
      expect(store.passwords['renter-1'], 'pw-12345');
    });

    test('email account without a password is refused', () async {
      final result = await link();

      expect(
        (result as Failure<LinkedAccount>).failure,
        isA<ValidationFailure>(),
      );
    });

    test('Google account stores no credential', () async {
      auth.user = anAuthUser(uid: 'g-2', provider: AuthProviderKind.google);

      await link();

      expect(store.accounts['g-2']?.authType, AuthProviderKind.google);
      expect(store.passwords.containsKey('g-2'), isFalse);
    });
  });
}
