import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/core/validation/validators.dart';

import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

/// Email and password sign-in. Checks the form before calling Firebase; the
/// password is only checked for being present, never for strength.
class LoginWithEmail {
  const LoginWithEmail(this._auth);

  final AuthRepository _auth;

  Future<Result<AuthUser>> call({
    required String email,
    required String password,
  }) {
    final problem =
        Validators.email(email) ??
        (password.isEmpty ? 'Enter your password.' : null);
    if (problem != null) {
      return Future.value(Result.failure(ValidationFailure(problem)));
    }
    return _auth.signInWithEmail(email: email.trim(), password: password);
  }
}
