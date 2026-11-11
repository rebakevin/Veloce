part of 'profile_bloc.dart';

/// Which profile form an action belongs to.
enum ProfileActionKind { updateProfile, licence, identity, payout }

/// Progress of the latest form submission.
enum ProfileActionStatus {
  idle,

  /// A request is running. Disable the submit button.
  submitting,

  /// Saved. React once (snackbar, pop), then send [ProfileActionAcknowledged].
  success,

  /// A field is wrong. [ProfileAction.message] is the text for the form.
  invalid,

  /// The simulated document check rejected the submission. Show
  /// [ProfileAction.message] and a Retry button (`ProfileLicenceRetried` or
  /// `ProfileIdentityRetried`); the user's input is kept.
  verificationFailed,

  /// Technical failure (network, permission). Show the message with Retry.
  failure,
}

/// Latest submission result, carried by [ProfileLoaded].
class ProfileAction extends Equatable {
  const ProfileAction({
    this.kind,
    this.status = ProfileActionStatus.idle,
    this.message,
  });

  static const ProfileAction idle = ProfileAction();

  final ProfileActionKind? kind;
  final ProfileActionStatus status;
  final String? message;

  bool get isSubmitting => status == ProfileActionStatus.submitting;

  @override
  List<Object?> get props => [kind, status, message];
}

sealed class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

final class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

/// The signed-in user's data. [licence] is only read for renters; [identity]
/// and [payout] only for owners. Each is `null` when not saved yet.
final class ProfileLoaded extends ProfileState {
  const ProfileLoaded({
    required this.account,
    required this.contact,
    this.licence,
    this.identity,
    this.payout,
    this.action = ProfileAction.idle,
  });

  final UserAccount account;
  final Contact contact;
  final Licence? licence;
  final OwnerIdentity? identity;
  final PayoutMethod? payout;
  final ProfileAction action;

  ProfileLoaded copyWith({
    UserAccount? account,
    Contact? contact,
    Licence? licence,
    OwnerIdentity? identity,
    PayoutMethod? payout,
    ProfileAction? action,
  }) {
    return ProfileLoaded(
      account: account ?? this.account,
      contact: contact ?? this.contact,
      licence: licence ?? this.licence,
      identity: identity ?? this.identity,
      payout: payout ?? this.payout,
      action: action ?? this.action,
    );
  }

  @override
  List<Object?> get props => [
    account,
    contact,
    licence,
    identity,
    payout,
    action,
  ];
}

final class ProfileFailure extends ProfileState {
  const ProfileFailure(this.error);

  final AppFailure error;

  @override
  List<Object?> get props => [error];
}
