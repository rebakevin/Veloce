import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/core/validation/validators.dart';

import '../repositories/auth_repository.dart';

/// Sends a password reset email. Firebase answers the same way for unknown
/// addresses, so the UI should not say whether the account exists.
class SendPasswordReset {
  const SendPasswordReset(this._auth);

  final AuthRepository _auth;

  Future<Result<void>> call(String email) {
    final problem = Validators.email(email);
    if (problem != null) {
      return Future.value(Result.failure(ValidationFailure(problem)));
    }
    return _auth.sendPasswordReset(email.trim());
  }
}
