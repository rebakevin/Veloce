import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

/// The signed-in user over time: `null` when signed out.
class ObserveAuthState {
  const ObserveAuthState(this._auth);

  final AuthRepository _auth;

  Stream<AuthUser?> call() => _auth.userChanges;
}
