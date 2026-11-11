import 'package:veloce/core/error/result.dart';

import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

/// Re-reads the signed-in user so `emailVerified` is current after the user
/// taps the link in the email.
class ReloadAuthUser {
  const ReloadAuthUser(this._auth);

  final AuthRepository _auth;

  Future<Result<AuthUser>> call() => _auth.reloadUser();
}
