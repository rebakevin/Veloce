import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:veloce/core/data/services/failure_mapper.dart';
import 'package:veloce/core/error/app_failure.dart';

/// Translates Firebase Auth and Google sign-in exceptions into [AppFailure]s
/// with messages safe to show. Wrong-password, unknown-account and invalid
/// credentials share one message, so the screen never reveals whether an
/// account exists (security.md). Credential problems are [ValidationFailure]s,
/// which `SwitchAccount` reads as "sign in again". Anything unexpected goes
/// through the shared [mapToFailure], which logs it once.
AppFailure mapAuthFailure(Object error, StackTrace stackTrace) {
  return switch (error) {
    FirebaseAuthException(:final code) =>
      _fromAuthCode(code) ?? mapToFailure(error, stackTrace),
    GoogleSignInException(:final code) =>
      _fromGoogleCode(code) ?? mapToFailure(error, stackTrace),
    _ => mapToFailure(error, stackTrace),
  };
}

AppFailure? _fromAuthCode(String code) {
  return switch (code) {
    'wrong-password' ||
    'invalid-credential' ||
    'user-not-found' ||
    'invalid-login-credentials' => const ValidationFailure(
      'Wrong email or password.',
    ),
    'invalid-email' => const ValidationFailure('Enter a valid email address.'),
    'weak-password' => const ValidationFailure(
      'That password is too weak. Use at least 8 characters with a letter and a number.',
    ),
    'email-already-in-use' => const ConflictFailure(
      'An account with this email already exists. Try logging in instead.',
    ),
    'account-exists-with-different-credential' => const ConflictFailure(
      'This email is registered with a different sign-in method.',
    ),
    'too-many-requests' => const ConflictFailure(
      'Too many attempts. Wait a few minutes and try again.',
    ),
    'user-disabled' => const PermissionFailure(
      'This account has been disabled. Contact support.',
    ),
    'requires-recent-login' => const PermissionFailure(
      'For your security, please sign in again and retry.',
    ),
    'network-request-failed' => const NetworkFailure(),
    'operation-not-allowed' => const UnknownFailure(
      'This sign-in method is not available right now.',
    ),
    _ => null,
  };
}

AppFailure? _fromGoogleCode(GoogleSignInExceptionCode code) {
  return switch (code) {
    GoogleSignInExceptionCode.canceled ||
    GoogleSignInExceptionCode.interrupted ||
    GoogleSignInExceptionCode.uiUnavailable => const ConflictFailure(
      'Google sign-in was cancelled.',
    ),
    GoogleSignInExceptionCode.clientConfigurationError ||
    GoogleSignInExceptionCode.providerConfigurationError =>
      const UnknownFailure(
        'Google sign-in is not set up on this device. Use email instead.',
      ),
    _ => null,
  };
}
