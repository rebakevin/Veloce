part of 'accounts_bloc.dart';

sealed class AccountsEvent extends Equatable {
  const AccountsEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the list. Also the Retry action after an [AccountsFailure].
final class AccountsStarted extends AccountsEvent {
  const AccountsStarted();
}

final class AccountsSwitchRequested extends AccountsEvent {
  const AccountsSwitchRequested(this.uid);

  final String uid;

  @override
  List<Object?> get props => [uid];
}

/// Removes the account from this device only.
final class AccountsRemoveRequested extends AccountsEvent {
  const AccountsRemoveRequested(this.uid);

  final String uid;

  @override
  List<Object?> get props => [uid];
}

/// Links the account that is signed in now. The UI first signs the new
/// account in (email form or Google chooser), then sends this. [password] is
/// required for email accounts.
final class AccountsAddRequested extends AccountsEvent {
  const AccountsAddRequested({this.password});

  final String? password;

  @override
  List<Object?> get props => [password];
}

/// Back to idle after the screen reacted to a result status.
final class AccountsResultAcknowledged extends AccountsEvent {
  const AccountsResultAcknowledged();
}
