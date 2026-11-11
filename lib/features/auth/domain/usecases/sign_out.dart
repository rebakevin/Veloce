import 'package:veloce/core/error/result.dart';

import '../repositories/auth_repository.dart';

/// Signs the user out of Firebase and Google. Linked accounts stay on the
/// device; removing them is a separate action.
class SignOut {
  const SignOut(this._auth);

  final AuthRepository _auth;

  Future<Result<void>> call() => _auth.signOut();
}
