part of 'login_bloc.dart';

enum LoginStatus {
  idle,

  /// Field errors are set; nothing was sent.
  invalid,
  submitting,

  /// Signed in (returning Google user included). The router takes over.
  success,

  /// Google sign-in worked but there is no profile yet: open role choice
  /// (the session is live, [AuthBloc] reports [AuthNeedsProfile]).
  needsRegistration,

  /// [LoginState.message] says why (wrong password, offline, cancelled).
  failure,
}

enum LoginMethod { email, google }

class LoginState extends Equatable {
  const LoginState({
    this.status = LoginStatus.idle,
    this.method,
    this.emailError,
    this.passwordError,
    this.message,
  });

  final LoginStatus status;

  /// Which button started the running request, only while submitting.
  final LoginMethod? method;
  final String? emailError;
  final String? passwordError;
  final String? message;

  bool get isSubmitting => status == LoginStatus.submitting;

  @override
  List<Object?> get props => [
    status,
    method,
    emailError,
    passwordError,
    message,
  ];
}
