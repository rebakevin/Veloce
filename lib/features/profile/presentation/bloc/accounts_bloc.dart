import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/auth/auth.dart';

part 'accounts_event.dart';
part 'accounts_state.dart';

/// Account switcher (spec §8.2).
///
/// Dispatch [AccountsStarted] on creation. It lists the linked accounts and,
/// when the signed-in account is not linked yet, tries to link it (works for
/// Google accounts and email accounts whose password is already stored; for
/// others the user adds it with [AccountsAddRequested]).
class AccountsBloc extends Bloc<AccountsEvent, AccountsState> {
  AccountsBloc({
    required ListLinkedAccounts listAccounts,
    required LinkCurrentAccount linkCurrent,
    required SwitchAccount switchAccount,
    required RemoveLinkedAccount removeAccount,
    required this._session,
  }) : _list = listAccounts,
       _link = linkCurrent,
       _switch = switchAccount,
       _remove = removeAccount,
       super(const AccountsLoading()) {
    on<AccountsStarted>(_onStarted);
    on<AccountsSwitchRequested>(_onSwitch);
    on<AccountsRemoveRequested>(_onRemove);
    on<AccountsAddRequested>(_onAdd);
    on<AccountsResultAcknowledged>(_onAcknowledged);
  }

  final ListLinkedAccounts _list;
  final LinkCurrentAccount _link;
  final SwitchAccount _switch;
  final RemoveLinkedAccount _remove;
  final AuthSession _session;

  Future<void> _onStarted(
    AccountsStarted event,
    Emitter<AccountsState> emit,
  ) async {
    emit(const AccountsLoading());
    var listed = await _list();
    if (isClosed) return;
    final currentUid = _session.currentUserId;
    if (listed case Success(:final value) when currentUid != null) {
      if (!value.any((account) => account.uid == currentUid)) {
        // Best effort: an email account without a stored password cannot be
        // linked silently, and simply stays out of the list until the user
        // adds it with their password.
        final linked = await _link();
        if (isClosed) return;
        if (linked is Success<LinkedAccount>) listed = await _list();
        if (isClosed) return;
      }
    }
    emit(switch (listed) {
      Success(:final value) => AccountsLoaded(
        accounts: value,
        currentUid: _session.currentUserId,
      ),
      Failure(:final failure) => AccountsFailure(failure),
    });
  }

  Future<void> _onSwitch(
    AccountsSwitchRequested event,
    Emitter<AccountsState> emit,
  ) async {
    final current = state;
    if (current is! AccountsLoaded || current.isWorking) return;
    final target = current.accountById(event.uid);
    if (target == null || target.uid == current.currentUid) return;

    emit(current.copyWith(status: AccountsStatus.working, target: target));
    final result = await _switch(event.uid);
    if (isClosed) return;
    switch (result) {
      case Success(value: SwitchOutcome.switched):
        emit(
          current.copyWith(
            currentUid: _session.currentUserId,
            status: AccountsStatus.switched,
            target: target,
          ),
        );
      case Success(value: SwitchOutcome.signInRequired):
        emit(
          current.copyWith(
            currentUid: _session.currentUserId,
            status: AccountsStatus.signInRequired,
            target: target,
          ),
        );
      case Failure(:final failure):
        emit(
          current.copyWith(
            currentUid: _session.currentUserId,
            status: AccountsStatus.failed,
            target: target,
            failure: failure,
          ),
        );
    }
  }

  Future<void> _onRemove(
    AccountsRemoveRequested event,
    Emitter<AccountsState> emit,
  ) async {
    final current = state;
    if (current is! AccountsLoaded || current.isWorking) return;
    final target = current.accountById(event.uid);
    if (target == null) return;

    emit(current.copyWith(status: AccountsStatus.working, target: target));
    final result = await _remove(event.uid);
    if (isClosed) return;
    if (result case Failure(:final failure)) {
      emit(
        current.copyWith(
          status: AccountsStatus.failed,
          target: target,
          failure: failure,
        ),
      );
      return;
    }
    emit(
      current.copyWith(
        accounts: [
          for (final account in current.accounts)
            if (account.uid != event.uid) account,
        ],
        status: AccountsStatus.removed,
        target: target,
      ),
    );
  }

  /// Links the account that is signed in right now, after the UI signed the
  /// new account in (see [AccountsAddRequested]).
  Future<void> _onAdd(
    AccountsAddRequested event,
    Emitter<AccountsState> emit,
  ) async {
    final current = state;
    if (current is! AccountsLoaded || current.isWorking) return;

    emit(current.copyWith(status: AccountsStatus.working));
    final linked = await _link(password: event.password);
    if (isClosed) return;
    if (linked case Failure(:final failure)) {
      emit(current.copyWith(status: AccountsStatus.failed, failure: failure));
      return;
    }
    final account = (linked as Success<LinkedAccount>).value;
    final listed = await _list();
    if (isClosed) return;
    emit(
      current.copyWith(
        accounts: listed is Success<List<LinkedAccount>>
            ? listed.value
            : [
                for (final item in current.accounts)
                  if (item.uid != account.uid) item,
                account,
              ],
        currentUid: _session.currentUserId,
        status: AccountsStatus.added,
        target: account,
      ),
    );
  }

  void _onAcknowledged(
    AccountsResultAcknowledged event,
    Emitter<AccountsState> emit,
  ) {
    final current = state;
    if (current is! AccountsLoaded || current.isWorking) return;
    emit(current.copyWith(status: AccountsStatus.idle));
  }
}
