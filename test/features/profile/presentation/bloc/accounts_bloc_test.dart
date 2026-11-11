import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/domain/enums/auth_provider_kind.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/auth/domain/entities/linked_account.dart';
import 'package:veloce/features/auth/domain/entities/switch_outcome.dart';
import 'package:veloce/features/auth/domain/usecases/link_current_account.dart';
import 'package:veloce/features/auth/domain/usecases/list_linked_accounts.dart';
import 'package:veloce/features/auth/domain/usecases/remove_linked_account.dart';
import 'package:veloce/features/auth/domain/usecases/switch_account.dart';
import 'package:veloce/features/profile/presentation/bloc/accounts_bloc.dart';

class _MockList extends Mock implements ListLinkedAccounts {}

class _MockLink extends Mock implements LinkCurrentAccount {}

class _MockSwitch extends Mock implements SwitchAccount {}

class _MockRemove extends Mock implements RemoveLinkedAccount {}

class _MockSession extends Mock implements AuthSession {}

void main() {
  late _MockList list;
  late _MockLink link;
  late _MockSwitch switchAccount;
  late _MockRemove remove;
  late _MockSession session;

  const renter = LinkedAccount(
    uid: 'r1',
    email: 'r1@example.com',
    name: 'Renter',
    role: UserRole.renter,
    authType: AuthProviderKind.password,
  );
  const owner = LinkedAccount(
    uid: 'o1',
    email: 'o1@example.com',
    name: 'Owner',
    role: UserRole.owner,
    authType: AuthProviderKind.google,
  );
  const loaded = AccountsLoaded(accounts: [renter, owner], currentUid: 'r1');

  setUp(() {
    list = _MockList();
    link = _MockLink();
    switchAccount = _MockSwitch();
    remove = _MockRemove();
    session = _MockSession();
    when(() => session.currentUserId).thenReturn('r1');
    when(() => list())
        .thenAnswer((_) async => const Result.success([renter, owner]));
  });

  AccountsBloc build() => AccountsBloc(
    listAccounts: list,
    linkCurrent: link,
    switchAccount: switchAccount,
    removeAccount: remove,
    session: session,
  );

  blocTest<AccountsBloc, AccountsState>(
    'lists accounts and marks the current one',
    build: build,
    act: (bloc) => bloc.add(const AccountsStarted()),
    expect: () => [const AccountsLoading(), loaded],
    verify: (bloc) {
      final state = bloc.state as AccountsLoaded;
      expect(state.isCurrent(renter), isTrue);
      expect(state.isCurrent(owner), isFalse);
      verifyNever(() => link(password: any(named: 'password')));
    },
  );

  blocTest<AccountsBloc, AccountsState>(
    'links the current account when it is missing from the list',
    setUp: () {
      var calls = 0;
      when(() => list()).thenAnswer((_) async {
        calls++;
        return Result.success(calls == 1 ? [owner] : [renter, owner]);
      });
      when(() => link()).thenAnswer((_) async => const Result.success(renter));
    },
    build: build,
    act: (bloc) => bloc.add(const AccountsStarted()),
    expect: () => [const AccountsLoading(), loaded],
  );

  blocTest<AccountsBloc, AccountsState>(
    'a list failure becomes a failure state',
    setUp: () =>
        when(() => list())
            .thenAnswer((_) async => const Result.failure(UnknownFailure())),
    build: build,
    act: (bloc) => bloc.add(const AccountsStarted()),
    expect: () => [
      const AccountsLoading(),
      const AccountsFailure(UnknownFailure()),
    ],
  );

  blocTest<AccountsBloc, AccountsState>(
    'switch success marks the new account current',
    setUp: () {
      when(
        () => switchAccount('o1'),
      ).thenAnswer((_) async => const Result.success(SwitchOutcome.switched));
      when(() => session.currentUserId).thenReturn('o1');
    },
    build: build,
    seed: () => loaded,
    act: (bloc) => bloc.add(const AccountsSwitchRequested('o1')),
    expect: () => [
      loaded.copyWith(status: AccountsStatus.working, target: owner),
      loaded.copyWith(
        currentUid: 'o1',
        status: AccountsStatus.switched,
        target: owner,
      ),
    ],
  );

  blocTest<AccountsBloc, AccountsState>(
    'switch asks for sign in again when the credential is gone',
    setUp: () => when(() => switchAccount('o1')).thenAnswer(
      (_) async => const Result.success(SwitchOutcome.signInRequired),
    ),
    build: build,
    seed: () => loaded,
    act: (bloc) => bloc.add(const AccountsSwitchRequested('o1')),
    expect: () => [
      isA<AccountsLoaded>(),
      isA<AccountsLoaded>()
          .having((s) => s.status, 'status', AccountsStatus.signInRequired)
          .having((s) => s.target, 'target', owner),
    ],
  );

  blocTest<AccountsBloc, AccountsState>(
    'switch failure keeps the list and reports the failure',
    setUp: () =>
        when(() => switchAccount('o1'))
            .thenAnswer((_) async => const Result.failure(NetworkFailure())),
    build: build,
    seed: () => loaded,
    act: (bloc) => bloc.add(const AccountsSwitchRequested('o1')),
    expect: () => [
      isA<AccountsLoaded>(),
      isA<AccountsLoaded>()
          .having((s) => s.status, 'status', AccountsStatus.failed)
          .having((s) => s.failure, 'failure', const NetworkFailure())
          .having((s) => s.accounts, 'accounts', [renter, owner]),
    ],
  );

  blocTest<AccountsBloc, AccountsState>(
    'switching to the current account does nothing',
    build: build,
    seed: () => loaded,
    act: (bloc) => bloc.add(const AccountsSwitchRequested('r1')),
    expect: () => <AccountsState>[],
    verify: (_) => verifyNever(() => switchAccount(any())),
  );

  blocTest<AccountsBloc, AccountsState>(
    'remove drops the account from the list',
    setUp: () =>
        when(() => remove('o1'))
            .thenAnswer((_) async => const Result.success(null)),
    build: build,
    seed: () => loaded,
    act: (bloc) => bloc.add(const AccountsRemoveRequested('o1')),
    expect: () => [
      isA<AccountsLoaded>(),
      isA<AccountsLoaded>()
          .having((s) => s.accounts, 'accounts', [renter])
          .having((s) => s.status, 'status', AccountsStatus.removed),
    ],
  );

  blocTest<AccountsBloc, AccountsState>(
    'add links the signed-in account and refreshes the list',
    setUp: () {
      when(() => link(password: 'secret123'))
          .thenAnswer((_) async => const Result.success(owner));
      when(() => session.currentUserId).thenReturn('o1');
    },
    build: build,
    seed: () => const AccountsLoaded(accounts: [renter], currentUid: 'r1'),
    act: (bloc) => bloc.add(const AccountsAddRequested(password: 'secret123')),
    expect: () => [
      isA<AccountsLoaded>(),
      isA<AccountsLoaded>()
          .having((s) => s.status, 'status', AccountsStatus.added)
          .having((s) => s.accounts, 'accounts', [renter, owner])
          .having((s) => s.currentUid, 'currentUid', 'o1'),
    ],
  );

  blocTest<AccountsBloc, AccountsState>(
    'add reports a failure such as a missing password',
    setUp: () => when(() => link(password: any(named: 'password'))).thenAnswer(
      (_) async => const Result.failure(ValidationFailure('Enter password.')),
    ),
    build: build,
    seed: () => loaded,
    act: (bloc) => bloc.add(const AccountsAddRequested()),
    expect: () => [
      isA<AccountsLoaded>(),
      isA<AccountsLoaded>().having(
        (s) => s.failure,
        'failure',
        const ValidationFailure('Enter password.'),
      ),
    ],
  );
}
