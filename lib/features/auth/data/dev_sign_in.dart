import 'package:firebase_auth/firebase_auth.dart';

import 'package:veloce/core/data/services/failure_mapper.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';

import '../domain/dev_account.dart';

/// Signs in seeded accounts for `/dev-login`. Registered in debug builds only.
class DevSignIn {
  const DevSignIn(this._auth);

  final FirebaseAuth _auth;

  Future<Result<void>> signIn(DevAccount account) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: account.email,
        password: DevAccounts.password,
      );
      return const Result.success(null);
    } on FirebaseAuthException catch (error, stackTrace) {
      if (error.code == 'invalid-credential' ||
          error.code == 'user-not-found') {
        return const Result.failure(
          ValidationFailure('Account not found. Run the seed script first.'),
        );
      }
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }

  Future<void> signOut() => _auth.signOut();
}
