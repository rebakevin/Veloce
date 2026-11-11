part of 'profile_bloc.dart';

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the profile and starts watching it. Dispatch once on creation; also
/// use it for the Retry button after a [ProfileFailure].
final class ProfileStarted extends ProfileEvent {
  const ProfileStarted();
}

final class ProfileUpdateSubmitted extends ProfileEvent {
  const ProfileUpdateSubmitted(this.update);

  final ProfileUpdate update;

  @override
  List<Object?> get props => [update];
}

final class ProfileLicenceSubmitted extends ProfileEvent {
  const ProfileLicenceSubmitted(this.submission);

  final LicenceSubmission submission;

  @override
  List<Object?> get props => [submission];
}

/// Sends the last licence submission again after a verification failure.
final class ProfileLicenceRetried extends ProfileEvent {
  const ProfileLicenceRetried();
}

final class ProfileIdentitySubmitted extends ProfileEvent {
  const ProfileIdentitySubmitted(this.submission);

  final IdentitySubmission submission;

  @override
  List<Object?> get props => [submission];
}

/// Sends the last identity submission again after a verification failure.
final class ProfileIdentityRetried extends ProfileEvent {
  const ProfileIdentityRetried();
}

/// [momoNumber] is the 9 digits after the leading 0.
final class ProfilePayoutSubmitted extends ProfileEvent {
  const ProfilePayoutSubmitted(this.momoNumber);

  final String momoNumber;

  @override
  List<Object?> get props => [momoNumber];
}

/// Clears the last action result back to idle once the screen has reacted.
final class ProfileActionAcknowledged extends ProfileEvent {
  const ProfileActionAcknowledged();
}

final class _ProfileAccountChanged extends ProfileEvent {
  const _ProfileAccountChanged(this.result);

  final Result<UserAccount> result;
}
