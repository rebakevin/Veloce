part of 'login_bloc.dart';

sealed class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props => [];
}

/// The Login button, with the current field text.
final class LoginSubmitted extends LoginEvent {
  const LoginSubmitted({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

enum LoginField { email, password }

/// The user typed in [field]: its inline error no longer applies.
final class LoginFieldEdited extends LoginEvent {
  const LoginFieldEdited(this.field);

  final LoginField field;

  @override
  List<Object?> get props => [field];
}

/// The "Continue with Google" button.
final class LoginGoogleRequested extends LoginEvent {
  const LoginGoogleRequested();
}
