import 'package:veloce/core/error/result.dart';

import '../entities/auth_user.dart';

/// Authentication with Firebase Auth and Google, behind our own contract.
/// Nothing here exposes SDK types, and failures come back as [Result]s with
/// user-facing messages.
abstract interface class AuthRepository {
  /// The signed-in user, or `null`.
  AuthUser? get currentUser;

  /// Emits on sign-in, sign-out and whenever the user is reloaded (for example
  /// after the email gets verified).
  Stream<AuthUser?> get userChanges;

  Future<Result<AuthUser>> createEmailUser({
    required String email,
    required String password,
    required String displayName,
  });

  Future<Result<AuthUser>> signInWithEmail({
    required String email,
    required String password,
  });

  /// Opens the Google chooser.
  Future<Result<AuthUser>> signInWithGoogle();

  /// Re-signs in the last Google account without UI. Success with `null`
  /// means the platform needs the user to interact.
  Future<Result<AuthUser?>> signInWithGoogleSilently();

  Future<Result<void>> sendPasswordReset(String email);

  Future<Result<void>> sendEmailVerification();

  /// Re-reads the user from the server and returns the fresh values.
  Future<Result<AuthUser>> reloadUser();

  /// Deletes the signed-in Auth user. Used to roll back a half-finished
  /// registration.
  Future<Result<void>> deleteCurrentUser();

  /// Full sign-out, including the Google session.
  Future<Result<void>> signOut();

  /// Signs out of Firebase only and keeps the Google session, so an account
  /// switch can silently sign a Google account back in.
  Future<Result<void>> suspendSession();
}
