part of 'accounts_bloc.dart';

enum AccountsStatus {
  idle,

  /// A switch, removal or add is running. Disable the list.
  working,

  /// The switch worked. The app resets route-level state and goes to the home
  /// of `target.role`, then sends [AccountsResultAcknowledged].
  switched,

  /// The stored sign-in is gone. Ask the user to sign in again as `target`
  /// (email form prefilled with `target.email`, or the Google chooser), then
  /// send [AccountsAddRequested].
  signInRequired,

  removed,
  added,

  /// See [AccountsLoaded.failure].
  failed,
}

sealed class AccountsState extends Equatable {
  const AccountsState();

  @override
  List<Object?> get props => [];
}

final class AccountsLoading extends AccountsState {
  const AccountsLoading();
}

/// [accounts] are the linked accounts; the one whose uid equals [currentUid]
/// is the "current" one. [target] is the account the last action was about.
final class AccountsLoaded extends AccountsState {
  const AccountsLoaded({
    required this.accounts,
    required this.currentUid,
    this.status = AccountsStatus.idle,
    this.target,
    this.failure,
  });

  final List<LinkedAccount> accounts;
  final String? currentUid;
  final AccountsStatus status;
  final LinkedAccount? target;

  /// Set when [status] is [AccountsStatus.failed].
  final AppFailure? failure;

  bool get isWorking => status == AccountsStatus.working;

  bool isCurrent(LinkedAccount account) => account.uid == currentUid;

  LinkedAccount? accountById(String uid) =>
      accounts.where((account) => account.uid == uid).firstOrNull;

  AccountsLoaded copyWith({
    List<LinkedAccount>? accounts,
    String? currentUid,
    AccountsStatus? status,
    LinkedAccount? target,
    AppFailure? failure,
  }) {
    return AccountsLoaded(
      accounts: accounts ?? this.accounts,
      currentUid: currentUid ?? this.currentUid,
      status: status ?? this.status,
      target: target ?? this.target,
      failure: failure,
    );
  }

  @override
  List<Object?> get props => [accounts, currentUid, status, target, failure];
}

final class AccountsFailure extends AccountsState {
  const AccountsFailure(this.error);

  final AppFailure error;

  @override
  List<Object?> get props => [error];
}
