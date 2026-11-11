import 'package:equatable/equatable.dart';

import 'auth_user.dart';

/// A finished registration. The account exists even when the verification
/// email could not be sent; the verify-email page offers a resend.
class RegistrationOutcome extends Equatable {
  const RegistrationOutcome({
    required this.user,
    required this.verificationEmailSent,
  });

  final AuthUser user;
  final bool verificationEmailSent;

  @override
  List<Object?> get props => [user, verificationEmailSent];
}
