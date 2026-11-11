import 'package:veloce/core/domain/enums/auth_provider_kind.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';

import '../entities/auth_user.dart';
import '../entities/linked_account.dart';
import '../entities/switch_outcome.dart';
import '../repositories/auth_repository.dart';
import '../repositories/linked_account_store.dart';

/// Switches to a linked account without asking for a password (spec §8.2).
///
/// Signs the current user out of Firebase (the linked list is kept), then signs
/// the target in: email accounts with the stored password, Google accounts
/// with a silent re-sign-in. When that cannot work (credential missing or
/// rejected, Google needs interaction, or a different Google account is
/// active) the result is [SwitchOutcome.signInRequired] and the UI asks the
/// user to sign in again. Network and other technical errors come back as
/// failures. The caller resets route-level blocs and navigates afterwards.
class SwitchAccount {
  const SwitchAccount({required this._auth, required this._store});

  final AuthRepository _auth;
  final LinkedAccountStore _store;

  Future<Result<SwitchOutcome>> call(String uid) async {
    final listed = await _store.list();
    if (listed case Failure(:final failure)) return Result.failure(failure);
    final accounts = (listed as Success<List<LinkedAccount>>).value;
    final target = accounts.where((account) => account.uid == uid).firstOrNull;
    if (target == null) return const Result.failure(NotFoundFailure());
    if (_auth.currentUser?.uid == uid) {
      return const Result.success(SwitchOutcome.switched);
    }

    final suspended = await _auth.suspendSession();
    if (suspended case Failure(:final failure)) return Result.failure(failure);

    return switch (target.authType) {
      AuthProviderKind.password => _signInWithStoredPassword(target),
      AuthProviderKind.google => _signInWithGoogleSilently(target),
    };
  }

  Future<Result<SwitchOutcome>> _signInWithStoredPassword(
    LinkedAccount target,
  ) async {
    final stored = await _store.passwordOf(target.uid);
    if (stored case Failure(:final failure)) return Result.failure(failure);
    final password = (stored as Success<String?>).value;
    if (password == null) {
      return const Result.success(SwitchOutcome.signInRequired);
    }

    final signedIn = await _auth.signInWithEmail(
      email: target.email,
      password: password,
    );
    return switch (signedIn) {
      Success() => const Result.success(SwitchOutcome.switched),
      // The credential mappers return ValidationFailure for a wrong or
      // outdated password and for accounts that no longer exist.
      Failure(failure: ValidationFailure()) => const Result.success(
        SwitchOutcome.signInRequired,
      ),
      Failure(:final failure) => Result.failure(failure),
    };
  }

  Future<Result<SwitchOutcome>> _signInWithGoogleSilently(
    LinkedAccount target,
  ) async {
    final signedIn = await _auth.signInWithGoogleSilently();
    if (signedIn case Failure(:final failure)) return Result.failure(failure);
    final AuthUser? user = (signedIn as Success<AuthUser?>).value;
    if (user == null) {
      return const Result.success(SwitchOutcome.signInRequired);
    }
    if (user.uid != target.uid) {
      // Google restored a different account than the one we want.
      await _auth.suspendSession();
      return const Result.success(SwitchOutcome.signInRequired);
    }
    return const Result.success(SwitchOutcome.switched);
  }
}
