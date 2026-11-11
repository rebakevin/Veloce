import 'package:veloce/core/error/result.dart';

import '../repositories/auth_repository.dart';

/// Sends (or resends) the verification email to the signed-in user.
class SendEmailVerification {
  const SendEmailVerification(this._auth);

  final AuthRepository _auth;

  Future<Result<void>> call() => _auth.sendEmailVerification();
}
