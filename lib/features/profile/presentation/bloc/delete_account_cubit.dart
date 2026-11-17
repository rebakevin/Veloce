import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/profile/domain/usecases/delete_account.dart';

sealed class DeleteAccountState extends Equatable {
  const DeleteAccountState();

  @override
  List<Object?> get props => [];
}

/// Waiting for the user to confirm.
final class DeleteAccountIdle extends DeleteAccountState {
  const DeleteAccountIdle();
}

/// Deleting. Disable the buttons and show progress.
final class DeleteAccountRunning extends DeleteAccountState {
  const DeleteAccountRunning();
}

/// Everything is gone and the user is signed out; the auth gate leaves the
/// screen, the dialog only has to close.
final class DeleteAccountDone extends DeleteAccountState {
  const DeleteAccountDone();
}

/// Show [error] and let the user try again; nothing is lost by retrying.
final class DeleteAccountFailure extends DeleteAccountState {
  const DeleteAccountFailure(this.error);

  final AppFailure error;

  @override
  List<Object?> get props => [error];
}

/// Account deletion behind the Profile tab's confirm dialog. A second call
/// while one is running is ignored.
class DeleteAccountCubit extends Cubit<DeleteAccountState> {
  DeleteAccountCubit({required this._deleteAccount})
    : super(const DeleteAccountIdle());

  final DeleteAccount _deleteAccount;

  /// Email accounts pass their [password]; Google accounts pass none.
  Future<void> delete({String? password}) async {
    if (state is DeleteAccountRunning) return;
    emit(const DeleteAccountRunning());
    final result = await _deleteAccount(password: password);
    if (isClosed) return;
    emit(switch (result) {
      Success() => const DeleteAccountDone(),
      Failure(:final failure) => DeleteAccountFailure(failure),
    });
  }
}
