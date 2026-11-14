import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:veloce/core/error/result.dart';
import 'package:veloce/core/validation/validators.dart';

import '../../domain/entities/google_sign_in_outcome.dart';
import '../../domain/usecases/link_current_account.dart';
import '../../domain/usecases/login_with_email.dart';
import '../../domain/usecases/sign_in_with_google.dart';

part 'login_event.dart';
part 'login_state.dart';

/// Email and Google sign-in. On [LoginStatus.success] the session is already
/// live: [AuthBloc] follows it and the router moves the user home, so the
/// screen only needs to stop showing the spinner.
///
/// A successful sign-in also links the account to this device (best effort,
/// after the result is emitted) so the account switcher can return to it.
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({
    required this._loginWithEmail,
    required this._signInWithGoogle,
    required this._linkCurrentAccount,
  }) : super(const LoginState()) {
    on<LoginSubmitted>(_onSubmitted);
    on<LoginGoogleRequested>(_onGoogleRequested);
    on<LoginFieldEdited>(_onFieldEdited);
  }

  final LoginWithEmail _loginWithEmail;
  final SignInWithGoogle _signInWithGoogle;
  final LinkCurrentAccount _linkCurrentAccount;

  /// Clears the edited field's inline error. Emits nothing otherwise, because
  /// the page's listener reacts to every state (a repeat would re-show the
  /// failure message).
  void _onFieldEdited(LoginFieldEdited event, Emitter<LoginState> emit) {
    if (state.status != LoginStatus.invalid) return;
    final emailError = event.field == LoginField.email
        ? null
        : state.emailError;
    final passwordError = event.field == LoginField.password
        ? null
        : state.passwordError;
    if (emailError == state.emailError &&
        passwordError == state.passwordError) {
      return;
    }
    emit(
      LoginState(
        status: emailError == null && passwordError == null
            ? LoginStatus.idle
            : LoginStatus.invalid,
        emailError: emailError,
        passwordError: passwordError,
      ),
    );
  }

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    if (state.isSubmitting) return;
    final emailError = Validators.email(event.email);
    final passwordError = event.password.isEmpty
        ? 'Enter your password.'
        : null;
    if (emailError != null || passwordError != null) {
      emit(
        LoginState(
          status: LoginStatus.invalid,
          emailError: emailError,
          passwordError: passwordError,
        ),
      );
      return;
    }

    emit(
      const LoginState(
        status: LoginStatus.submitting,
        method: LoginMethod.email,
      ),
    );
    final result = await _loginWithEmail(
      email: event.email,
      password: event.password,
    );
    if (isClosed) return;
    emit(
      result.when(
        success: (_) => const LoginState(status: LoginStatus.success),
        failure: (failure) =>
            LoginState(status: LoginStatus.failure, message: failure.message),
      ),
    );
    if (result case Success()) {
      unawaited(_linkCurrentAccount(password: event.password));
    }
  }

  Future<void> _onGoogleRequested(
    LoginGoogleRequested event,
    Emitter<LoginState> emit,
  ) async {
    if (state.isSubmitting) return;
    emit(
      const LoginState(
        status: LoginStatus.submitting,
        method: LoginMethod.google,
      ),
    );
    final result = await _signInWithGoogle();
    if (isClosed) return;
    emit(
      result.when(
        success: (outcome) => switch (outcome) {
          ReturningGoogleUser() => const LoginState(
            status: LoginStatus.success,
          ),
          NewGoogleUser() => const LoginState(
            status: LoginStatus.needsRegistration,
          ),
        },
        failure: (failure) =>
            LoginState(status: LoginStatus.failure, message: failure.message),
      ),
    );
    if (result case Success(value: ReturningGoogleUser())) {
      unawaited(_linkCurrentAccount());
    }
  }
}
