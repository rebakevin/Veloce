part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatch once at app start. Subscribes to the Firebase user; the first
/// emission restores a persisted session.
final class AuthStarted extends AuthEvent {
  const AuthStarted();
}

/// The signed-in user changed (`null` = signed out). Sent by the stream.
final class AuthUserChanged extends AuthEvent {
  const AuthUserChanged(this.user);

  final AuthUser? user;

  @override
  List<Object?> get props => [user];
}

/// Re-reads `users/{uid}`. Dispatch after a registration finished (Google
/// path and email path) so the state moves to [AuthAuthenticated], and for a
/// Retry after [AuthProfileFailed].
final class AuthProfileRefreshed extends AuthEvent {
  const AuthProfileRefreshed();
}

/// Reloads the Firebase user so `isEmailVerified` is current.
final class EmailVerificationRefreshed extends AuthEvent {
  const EmailVerificationRefreshed();
}

final class SignOutRequested extends AuthEvent {
  const SignOutRequested();
}
