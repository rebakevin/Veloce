import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/features/auth/data/auth_failure_mapper.dart';

AppFailure map(String code) =>
    mapAuthFailure(FirebaseAuthException(code: code), StackTrace.empty);

void main() {
  test('wrong password, unknown user and bad credential share one message', () {
    final messages = {
      for (final code in [
        'wrong-password',
        'user-not-found',
        'invalid-credential',
      ])
        map(code).message,
    };

    expect(messages, {'Wrong email or password.'});
    expect(map('wrong-password'), isA<ValidationFailure>());
  });

  test('registration problems are specific', () {
    expect(map('email-already-in-use'), isA<ConflictFailure>());
    expect(map('email-already-in-use').message, contains('already exists'));
    expect(map('weak-password').message, contains('8 characters'));
    expect(map('invalid-email').message, contains('valid email'));
  });

  test(
    'throttling, disabled accounts and stale logins have their own types',
    () {
      expect(map('too-many-requests'), isA<ConflictFailure>());
      expect(map('user-disabled'), isA<PermissionFailure>());
      expect(map('requires-recent-login').message, contains('sign in again'));
      expect(
        map('account-exists-with-different-credential').message,
        contains('different sign-in method'),
      );
    },
  );

  test('network errors map to NetworkFailure', () {
    expect(map('network-request-failed'), isA<NetworkFailure>());
  });

  test('an unknown code falls back to a generic message without the code', () {
    final failure = map('internal-error');

    expect(failure, isA<UnknownFailure>());
    expect(failure.message, isNot(contains('internal-error')));
  });

  test('cancelling the Google chooser is a friendly conflict', () {
    final failure = mapAuthFailure(
      const GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
      StackTrace.empty,
    );

    expect(failure, isA<ConflictFailure>());
    expect(failure.message, 'Google sign-in was cancelled.');
  });
}
