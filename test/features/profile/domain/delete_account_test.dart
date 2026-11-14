import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/domain/enums/auth_provider_kind.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/auth/domain/repositories/linked_account_store.dart';
import 'package:veloce/features/profile/domain/repositories/account_eraser.dart';
import 'package:veloce/features/profile/domain/usecases/delete_account.dart';

import '../../auth/domain/auth_fakes.dart';

class _MockEraser extends Mock implements AccountEraser {}

class _MockLinkedAccounts extends Mock implements LinkedAccountStore {}

void main() {
  late FakeAuthRepository auth;
  late _MockEraser eraser;
  late _MockLinkedAccounts linked;
  late DeleteAccount deleteAccount;

  setUp(() {
    auth = FakeAuthRepository()..user = anAuthUser();
    eraser = _MockEraser();
    linked = _MockLinkedAccounts();
    when(() => eraser.eraseAll(any()))
        .thenAnswer((_) async => const Result.success(null));
    when(() => linked.remove(any()))
        .thenAnswer((_) async => const Result.success(null));
    deleteAccount = DeleteAccount(
      auth: auth,
      eraser: eraser,
      linkedAccounts: linked,
    );
  });

  test(
    're-authenticates, erases the data, then deletes the Auth user',
    () async {
      final result = await deleteAccount(password: 'secret123');

      expect(result, isA<Success<void>>());
      expect(auth.calls, ['reauth:secret123', 'deleteUser', 'signOut']);
      verify(() => eraser.eraseAll('uid-1')).called(1);
      verify(() => linked.remove('uid-1')).called(1);
    },
  );

  test('an email account without a password changes nothing', () async {
    final result = await deleteAccount(password: '');

    expect((result as Failure<void>).failure, isA<ValidationFailure>());
    expect(auth.calls, isEmpty);
    verifyZeroInteractions(eraser);
  });

  test('a Google account needs no password', () async {
    auth.user = anAuthUser(provider: AuthProviderKind.google);

    final result = await deleteAccount();

    expect(result, isA<Success<void>>());
    expect(auth.calls, ['reauth:null', 'deleteUser', 'signOut']);
  });

  test('a failed re-authentication keeps all data', () async {
    auth.reauthResult = const Result.failure(
      ValidationFailure('Wrong email or password.'),
    );

    final result = await deleteAccount(password: 'wrong');

    expect(
      (result as Failure<void>).failure.message,
      'Wrong email or password.',
    );
    verifyZeroInteractions(eraser);
    verifyNever(() => linked.remove(any()));
    expect(auth.calls, ['reauth:wrong']);
  });

  test('a failed erase keeps the Auth user so the user can retry', () async {
    when(() => eraser.eraseAll(any()))
        .thenAnswer((_) async => const Result.failure(NetworkFailure()));

    final result = await deleteAccount(password: 'secret123');

    expect((result as Failure<void>).failure, isA<NetworkFailure>());
    expect(auth.calls, ['reauth:secret123']);
    verifyNever(() => linked.remove(any()));
  });

  test('nobody signed in fails without touching anything', () async {
    auth.user = null;

    final result = await deleteAccount(password: 'secret123');

    expect((result as Failure<void>).failure, isA<PermissionFailure>());
    verifyZeroInteractions(eraser);
  });
}
