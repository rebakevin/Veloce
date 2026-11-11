import 'package:equatable/equatable.dart';

import 'package:veloce/core/domain/entities/user_account.dart';

import 'auth_user.dart';

/// Result of a Google sign-in: a returning user goes to Home, a first-time
/// user continues to role choice and the document steps.
sealed class GoogleSignInOutcome extends Equatable {
  const GoogleSignInOutcome(this.user);

  final AuthUser user;

  @override
  List<Object?> get props => [user];
}

/// `users/{uid}` exists.
final class ReturningGoogleUser extends GoogleSignInOutcome {
  const ReturningGoogleUser(super.user, this.profile);

  final UserAccount profile;

  @override
  List<Object?> get props => [user, profile];
}

/// Signed in, but there is no `users/{uid}` yet.
final class NewGoogleUser extends GoogleSignInOutcome {
  const NewGoogleUser(super.user);
}
