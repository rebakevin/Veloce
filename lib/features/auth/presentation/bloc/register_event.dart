part of 'register_bloc.dart';

sealed class RegisterEvent extends Equatable {
  const RegisterEvent();

  @override
  List<Object?> get props => [];
}

/// Step 1: the role card was tapped. Moves to the details step.
final class RegisterRoleSelected extends RegisterEvent {
  const RegisterRoleSelected(this.role);

  final UserRole role;

  @override
  List<Object?> get props => [role];
}

/// A field on the details step changed. Only the fields passed are updated,
/// and the error shown on them is cleared.
final class RegisterDraftEdited extends RegisterEvent {
  const RegisterDraftEdited({
    this.name,
    this.phone,
    this.email,
    this.password,
    this.dateOfBirth,
    this.documentNumber,
    this.licenceExpiry,
    this.photoBytes,
    this.photoExtension,
  });

  final String? name;
  final String? phone;
  final String? email;
  final String? password;
  final DateTime? dateOfBirth;
  final String? documentNumber;
  final DateTime? licenceExpiry;
  final Uint8List? photoBytes;
  final String? photoExtension;

  @override
  List<Object?> get props => [
    name,
    phone,
    email,
    password,
    dateOfBirth,
    documentNumber,
    licenceExpiry,
    photoBytes,
    photoExtension,
  ];
}

/// "Continue" on the details step. Validates every field; email users then
/// get an OTP, Google users are registered straight away.
final class RegisterDetailsSubmitted extends RegisterEvent {
  const RegisterDetailsSubmitted();
}

/// "Verify" on the OTP step.
final class RegisterOtpSubmitted extends RegisterEvent {
  const RegisterOtpSubmitted(this.code);

  final String code;

  @override
  List<Object?> get props => [code];
}

final class RegisterOtpResent extends RegisterEvent {
  const RegisterOtpResent();
}

/// Retry after a failed final step (document check, email taken, offline).
final class RegisterSubmitRetried extends RegisterEvent {
  const RegisterSubmitRetried();
}

/// One step back. Ignored on the role step, while busy and once done.
final class RegisterBackPressed extends RegisterEvent {
  const RegisterBackPressed();
}
