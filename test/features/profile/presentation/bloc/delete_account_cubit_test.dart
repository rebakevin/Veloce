import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/profile/domain/usecases/delete_account.dart';
import 'package:veloce/features/profile/presentation/bloc/delete_account_cubit.dart';

class _MockDeleteAccount extends Mock implements DeleteAccount {}

void main() {
  late _MockDeleteAccount deleteAccount;

  setUp(() => deleteAccount = _MockDeleteAccount());

  blocTest<DeleteAccountCubit, DeleteAccountState>(
    'running, then done, when the account is deleted',
    setUp: () =>
        when(() => deleteAccount(password: 'secret123'))
            .thenAnswer((_) async => const Result.success(null)),
    build: () => DeleteAccountCubit(deleteAccount: deleteAccount),
    act: (cubit) => cubit.delete(password: 'secret123'),
    expect: () => [const DeleteAccountRunning(), const DeleteAccountDone()],
  );

  blocTest<DeleteAccountCubit, DeleteAccountState>(
    'reports the failure so the user can try again',
    setUp: () => when(() => deleteAccount(password: 'nope')).thenAnswer(
      (_) async =>
          const Result.failure(ValidationFailure('Wrong email or password.')),
    ),
    build: () => DeleteAccountCubit(deleteAccount: deleteAccount),
    act: (cubit) => cubit.delete(password: 'nope'),
    expect: () => [
      const DeleteAccountRunning(),
      const DeleteAccountFailure(ValidationFailure('Wrong email or password.')),
    ],
  );

  blocTest<DeleteAccountCubit, DeleteAccountState>(
    'a second tap while deleting is ignored',
    setUp: () =>
        when(() => deleteAccount(password: any(named: 'password')))
            .thenAnswer((_) async => const Result.success(null)),
    build: () => DeleteAccountCubit(deleteAccount: deleteAccount),
    act: (cubit) {
      cubit
        ..delete(password: 'a')
        ..delete(password: 'a');
    },
    verify: (_) => verify(() => deleteAccount(password: 'a')).called(1),
  );
}
