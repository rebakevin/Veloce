import 'package:veloce/core/domain/enums/auth_provider_kind.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/auth/auth.dart';

import '../repositories/account_eraser.dart';

/// Deletes the signed-in account and all its data, then signs out.
///
/// Email accounts re-authenticate with their [password] first, because
/// Firebase refuses to delete an old session and the data would already be
/// gone by then, then the data goes while the session can still write, then
/// the Auth user. Google accounts have no silent re-authentication, and the
/// user must not be prompted, so for them the data goes and the Auth user is
/// deleted only if Firebase allows it without a fresh sign-in. Otherwise the
/// bare Auth record stays; with no profile it is treated as a new user, so
/// signing up with Google again starts a fresh account.
class DeleteAccount {
  const DeleteAccount({
    required this._auth,
    required this._eraser,
    required this._linkedAccounts,
  });

  final AuthRepository _auth;
  final AccountEraser _eraser;
  final LinkedAccountStore _linkedAccounts;

  Future<Result<void>> call({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) {
      return const Result.failure(PermissionFailure('Sign in first.'));
    }
    final isEmail = user.provider == AuthProviderKind.password;
    if (isEmail && (password == null || password.isEmpty)) {
      return const Result.failure(
        ValidationFailure('Enter your password to confirm.'),
      );
    }

    if (isEmail) {
      final confirmed = await _auth.reauthenticate(password: password!);
      if (confirmed case Failure(:final failure)) {
        return Result.failure(failure);
      }
    }

    final erased = await _eraser.eraseAll(user.uid);
    if (erased case Failure(:final failure)) return Result.failure(failure);

    final removed = await _auth.deleteCurrentUser();
    if (removed case Failure(:final failure) when isEmail) {
      return Result.failure(failure);
    }

    // The account no longer exists, so failures here change nothing. Signing
    // out also ends the Google session, so the user must sign in or sign up
    // again.
    await _auth.signOut();
    await _linkedAccounts.remove(user.uid);
    return const Result.success(null);
  }
}
