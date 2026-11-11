part of 'auth_bloc.dart';

/// Where the session stands. Listen to this to decide where to navigate.
sealed class AuthState extends Equatable {
  const AuthState();

  /// The signed-in Firebase user, whatever the profile state.
  AuthUser? get user => null;

  bool get isEmailVerified => user?.emailVerified ?? false;

  @override
  List<Object?> get props => [user];
}

/// Nothing known yet (app start). Show the splash.
final class AuthUnknown extends AuthState {
  const AuthUnknown();
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Signed in with a complete profile.
final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required this.user, required this.account});

  @override
  final AuthUser user;
  final UserAccount account;

  UserRole get role => account.role;

  @override
  List<Object?> get props => [user, account];
}

/// Signed in but `users/{uid}` does not exist yet. For a Google user
/// ([needsRoleChoice]) this is the first sign-in: send them to role choice and
/// the document steps. For an email user it is the short moment while their
/// registration is still being written; stay on the register flow and
/// dispatch [AuthProfileRefreshed] when it is done.
final class AuthNeedsProfile extends AuthState {
  const AuthNeedsProfile(this.user);

  @override
  final AuthUser user;

  bool get needsRoleChoice => user.provider == AuthProviderKind.google;
}

/// Signed in but the profile could not be read (offline). Offer Retry via
/// [AuthProfileRefreshed] or sign-out.
final class AuthProfileFailed extends AuthState {
  const AuthProfileFailed(this.user, this.message);

  @override
  final AuthUser user;
  final String message;

  @override
  List<Object?> get props => [user, message];
}
