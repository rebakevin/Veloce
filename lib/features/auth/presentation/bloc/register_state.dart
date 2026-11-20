part of 'register_bloc.dart';

enum RegisterStep { role, details, submitting, done }

enum RegisterStatus {
  idle,

  /// A request is running; disable the buttons.
  busy,

  /// The last request failed. [RegisterState.message] says why. On the
  /// submitting step use [RegisterSubmitRetried] or go back.
  failure,
}

enum RegisterField {
  name,
  phone,
  email,
  password,
  dateOfBirth,
  documentNumber,
  licenceExpiry,
  photo,
}

class RegisterState extends Equatable {
  const RegisterState({
    this.step = RegisterStep.role,
    this.status = RegisterStatus.idle,
    this.draft = const RegisterDraft(),
    this.fieldErrors = const {},
    this.message,
    this.googleUser,
    this.verificationEmailSent = false,
  });

  final RegisterStep step;
  final RegisterStatus status;
  final RegisterDraft draft;

  /// Inline message per field of the details step.
  final Map<RegisterField, String> fieldErrors;

  /// Failure text for the current step, or `null`.
  final String? message;

  /// Set when the flow follows a first Google sign-in: no email or password
  /// steps.
  final AuthUser? googleUser;

  /// Set on [RegisterStep.done]: whether a verification email went out.
  /// `false` for a Google account (already verified, nothing mailed) or when
  /// the email could not be sent (the verify-email page offers a resend).
  final bool verificationEmailSent;

  bool get isGoogle => googleUser != null;
  bool get isBusy => status == RegisterStatus.busy;

  RegisterState copyWith({
    RegisterStep? step,
    RegisterStatus? status,
    RegisterDraft? draft,
    Map<RegisterField, String>? fieldErrors,
    String? message,
    bool? verificationEmailSent,
  }) => RegisterState(
    step: step ?? this.step,
    status: status ?? this.status,
    draft: draft ?? this.draft,
    fieldErrors: fieldErrors ?? this.fieldErrors,
    message: message,
    googleUser: googleUser,
    verificationEmailSent: verificationEmailSent ?? this.verificationEmailSent,
  );

  @override
  List<Object?> get props => [
    step,
    status,
    draft,
    fieldErrors,
    message,
    googleUser,
    verificationEmailSent,
  ];
}
