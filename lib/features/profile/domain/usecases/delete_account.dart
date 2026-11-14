import 'package:veloce/core/domain/enums/auth_provider_kind.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/auth/auth.dart';

import '../repositories/account_eraser.dart';

/// Deletes the signed-in account and all its data.
///
/// Order matters: the user is re-authenticated first, because Firebase refuses
/// to delete an old session and the data is already gone by then; the data
/// goes while the session can still write; the Auth user goes last. Email
/// accounts must pass their [password].
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
    final needsPassword = user.provider == AuthProviderKind.password;
    if (needsPassword && (password == null || password.isEmpty)) {
      return const Result.failure(
        ValidationFailure('Enter your password to confirm.'),
      );
    }

    final confirmed = await _auth.reauthenticate(password: password);
    if (confirmed case Failure(:final failure)) return Result.failure(failure);

    final erased = await _eraser.eraseAll(user.uid);
    if (erased case Failure(:final failure)) return Result.failure(failure);

    final removed = await _auth.deleteCurrentUser();
    if (removed case Failure(:final failure)) return Result.failure(failure);

    // The account no longer exists, so failures here change nothing. Signing
    // out also ends the Google session, so the user must sign in or sign up
    // again.
    await _auth.signOut();
    await _linkedAccounts.remove(user.uid);
    return const Result.success(null);
  }
}
