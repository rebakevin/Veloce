import 'package:veloce/core/error/result.dart';

import '../entities/auth_user.dart';
import '../entities/google_sign_in_outcome.dart';
import '../repositories/auth_repository.dart';
import '../repositories/registration_store.dart';

/// Google sign-in. A returning user (profile exists) goes to Home, a first-time
/// user continues to role choice and the document steps.
class SignInWithGoogle {
  const SignInWithGoogle({required this._auth, required this._store});

  final AuthRepository _auth;
  final RegistrationStore _store;

  Future<Result<GoogleSignInOutcome>> call() async {
    final signedIn = await _auth.signInWithGoogle();
    if (signedIn case Failure(:final failure)) return Result.failure(failure);
    final user = (signedIn as Success<AuthUser>).value;

    final found = await _store.findProfile(user.uid);
    return switch (found) {
      Failure(:final failure) => Result.failure(failure),
      Success(:final value) when value == null => Result.success(
        NewGoogleUser(user),
      ),
      Success(:final value) => Result.success(
        ReturningGoogleUser(user, value!),
      ),
    };
  }
}
