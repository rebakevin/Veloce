import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/usecases/reload_auth_user.dart';
import '../../domain/usecases/send_email_verification.dart';

enum VerifyEmailStatus {
  idle,
  resending,

  /// A new email went out.
  resent,
  checking,

  /// The user reloaded and the email is confirmed. Dispatch
  /// `EmailVerificationRefreshed` on [AuthBloc] so the app learns it, then
  /// leave the page.
  verified,

  /// Reloaded, but the link has not been opened yet.
  notVerifiedYet,

  /// [VerifyEmailState.message] says why.
  failure,
}

class VerifyEmailState extends Equatable {
  const VerifyEmailState({this.status = VerifyEmailStatus.idle, this.message});

  final VerifyEmailStatus status;
  final String? message;

  bool get isBusy =>
      status == VerifyEmailStatus.resending ||
      status == VerifyEmailStatus.checking;

  @override
  List<Object?> get props => [status, message];
}

/// The verify-email-pending page: resend the link, or confirm it was opened.
class VerifyEmailCubit extends Cubit<VerifyEmailState> {
  VerifyEmailCubit({required this._sendVerification, required this._reloadUser})
    : super(const VerifyEmailState());

  final SendEmailVerification _sendVerification;
  final ReloadAuthUser _reloadUser;

  Future<void> resend() async {
    if (state.isBusy) return;
    emit(const VerifyEmailState(status: VerifyEmailStatus.resending));
    final result = await _sendVerification();
    if (isClosed) return;
    emit(
      result.when(
        success: (_) =>
            const VerifyEmailState(status: VerifyEmailStatus.resent),
        failure: (failure) => VerifyEmailState(
          status: VerifyEmailStatus.failure,
          message: failure.message,
        ),
      ),
    );
  }

  /// "I've verified my email".
  Future<void> checkVerified() async {
    if (state.isBusy) return;
    emit(const VerifyEmailState(status: VerifyEmailStatus.checking));
    final result = await _reloadUser();
    if (isClosed) return;
    emit(
      result.when(
        success: (user) => VerifyEmailState(
          status: user.emailVerified
              ? VerifyEmailStatus.verified
              : VerifyEmailStatus.notVerifiedYet,
        ),
        failure: (failure) => VerifyEmailState(
          status: VerifyEmailStatus.failure,
          message: failure.message,
        ),
      ),
    );
  }
}
