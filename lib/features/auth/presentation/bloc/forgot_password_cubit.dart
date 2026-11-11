import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:veloce/core/validation/validators.dart';

import '../../domain/usecases/send_password_reset.dart';

enum ForgotPasswordStatus { idle, sending, sent, failure }

class ForgotPasswordState extends Equatable {
  const ForgotPasswordState({
    this.status = ForgotPasswordStatus.idle,
    this.emailError,
    this.message,
  });

  final ForgotPasswordStatus status;
  final String? emailError;

  /// Failure text (offline, rate limited). Not set for unknown addresses:
  /// Firebase answers the same, so [sent] never reveals whether one exists.
  final String? message;

  @override
  List<Object?> get props => [status, emailError, message];
}

class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  ForgotPasswordCubit(this._sendPasswordReset)
    : super(const ForgotPasswordState());

  final SendPasswordReset _sendPasswordReset;

  Future<void> submit(String email) async {
    if (state.status == ForgotPasswordStatus.sending) return;
    final problem = Validators.email(email);
    if (problem != null) {
      emit(ForgotPasswordState(emailError: problem));
      return;
    }
    emit(const ForgotPasswordState(status: ForgotPasswordStatus.sending));
    final result = await _sendPasswordReset(email);
    if (isClosed) return;
    emit(
      result.when(
        success: (_) =>
            const ForgotPasswordState(status: ForgotPasswordStatus.sent),
        failure: (failure) => ForgotPasswordState(
          status: ForgotPasswordStatus.failure,
          message: failure.message,
        ),
      ),
    );
  }

  /// Back to the form, for "use a different email".
  void reset() => emit(const ForgotPasswordState());
}
