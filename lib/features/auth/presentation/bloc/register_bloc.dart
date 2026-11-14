import 'dart:async';
import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/domain/services/verification_provider.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/core/validation/validators.dart';

import '../../domain/entities/auth_user.dart';
import '../../domain/entities/google_registration_input.dart';
import '../../domain/entities/registration_document.dart';
import '../../domain/entities/registration_input.dart';
import '../../domain/usecases/complete_google_registration.dart';
import '../../domain/usecases/link_current_account.dart';
import '../../domain/usecases/register_with_email.dart';
import 'register_draft.dart';

part 'register_event.dart';
part 'register_state.dart';

/// The multi-step sign-up: role, details, phone OTP, then the final write.
///
/// Email users go role -> details -> otp -> submitting -> done. Pass
/// [googleUser] (the user from [AuthNeedsProfile]) for the Google path: the
/// email and password fields are skipped, there is no OTP, and the final step
/// calls `CompleteGoogleRegistration`.
///
/// A finished sign-up also links the new account to this device (best effort,
/// after the result is emitted) so the account switcher can return to it.
///
/// On [RegisterStep.done] the screen dispatches `AuthProfileRefreshed` on
/// [AuthBloc], then goes to the verify-email page (email users) or home.
class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  RegisterBloc({
    required this._registerWithEmail,
    required this._completeGoogle,
    required this._linkCurrentAccount,
    required this._verification,
    required this._clock,
    AuthUser? googleUser,
  }) : super(
         RegisterState(
           googleUser: googleUser,
           draft: RegisterDraft(
             name: googleUser?.displayName ?? '',
             email: googleUser?.email ?? '',
           ),
         ),
       ) {
    on<RegisterRoleSelected>(_onRoleSelected);
    on<RegisterDraftEdited>(_onDraftEdited);
    on<RegisterDetailsSubmitted>(_onDetailsSubmitted);
    on<RegisterOtpSubmitted>(_onOtpSubmitted);
    on<RegisterOtpResent>(_onOtpResent);
    on<RegisterSubmitRetried>(_onSubmitRetried);
    on<RegisterBackPressed>(_onBackPressed);
  }

  final RegisterWithEmail _registerWithEmail;
  final CompleteGoogleRegistration _completeGoogle;
  final LinkCurrentAccount _linkCurrentAccount;
  final VerificationProvider _verification;
  final Clock _clock;

  void _onRoleSelected(
    RegisterRoleSelected event,
    Emitter<RegisterState> emit,
  ) {
    if (state.step != RegisterStep.role) return;
    final draft = state.draft;
    emit(
      state.copyWith(
        step: RegisterStep.details,
        // A different role asks for a different document.
        draft: draft.role == event.role ? draft : _withRole(draft, event.role),
        fieldErrors: const {},
      ),
    );
  }

  RegisterDraft _withRole(RegisterDraft old, UserRole role) => RegisterDraft(
    role: role,
    name: old.name,
    phone: old.phone,
    email: old.email,
    password: old.password,
    dateOfBirth: old.dateOfBirth,
    photoExtension: old.photoExtension,
  );

  void _onDraftEdited(RegisterDraftEdited event, Emitter<RegisterState> emit) {
    final old = state.draft;
    final draft = RegisterDraft(
      role: old.role,
      name: event.name ?? old.name,
      phone: event.phone ?? old.phone,
      email: event.email ?? old.email,
      password: event.password ?? old.password,
      dateOfBirth: event.dateOfBirth ?? old.dateOfBirth,
      documentNumber: event.documentNumber ?? old.documentNumber,
      licenceExpiry: event.licenceExpiry ?? old.licenceExpiry,
      photoBytes: event.photoBytes ?? old.photoBytes,
      photoExtension: event.photoExtension ?? old.photoExtension,
    );
    final edited = {
      if (event.name != null) RegisterField.name,
      if (event.phone != null) RegisterField.phone,
      if (event.email != null) RegisterField.email,
      if (event.password != null) RegisterField.password,
      if (event.dateOfBirth != null) RegisterField.dateOfBirth,
      if (event.documentNumber != null) RegisterField.documentNumber,
      if (event.licenceExpiry != null) RegisterField.licenceExpiry,
      if (event.photoBytes != null) RegisterField.photo,
    };
    final errors = {...state.fieldErrors}
      ..removeWhere((k, _) => edited.contains(k));
    emit(state.copyWith(draft: draft, fieldErrors: errors));
  }

  Future<void> _onDetailsSubmitted(
    RegisterDetailsSubmitted event,
    Emitter<RegisterState> emit,
  ) async {
    if (state.step != RegisterStep.details || state.isBusy) return;
    final errors = _validateDetails();
    if (errors.isNotEmpty) {
      emit(state.copyWith(fieldErrors: errors, status: RegisterStatus.idle));
      return;
    }
    if (state.isGoogle) {
      await _submit(emit);
    } else {
      await _sendOtp(emit);
    }
  }

  Map<RegisterField, String> _validateDetails() {
    final draft = state.draft;
    final now = _clock.now();
    final role = draft.role;
    final googleUser = state.isGoogle;
    final errors = <RegisterField, String?>{
      RegisterField.name: Validators.requiredText(draft.name, field: 'Name'),
      RegisterField.phone: Validators.phone(draft.phone),
      if (!googleUser) RegisterField.email: Validators.email(draft.email),
      if (!googleUser)
        RegisterField.password: Validators.password(draft.password),
      RegisterField.dateOfBirth: Validators.dateOfBirth(
        draft.dateOfBirth,
        now: now,
      ),
      RegisterField.documentNumber: switch (role) {
        UserRole.owner => Validators.nationalId(draft.documentNumber),
        _ => Validators.licenceNumber(draft.documentNumber),
      },
      if (role != UserRole.owner)
        RegisterField.licenceExpiry: Validators.licenceExpiry(
          draft.licenceExpiry,
          now: now,
        ),
      RegisterField.photo: (draft.photoBytes?.isEmpty ?? true)
          ? 'Add a photo of your document.'
          : null,
    };
    return {
      for (final entry in errors.entries)
        if (entry.value != null) entry.key: entry.value!,
    };
  }

  Future<void> _sendOtp(Emitter<RegisterState> emit) async {
    emit(state.copyWith(status: RegisterStatus.busy));
    final result = await _verification.sendOtp(state.draft.phone.trim());
    if (isClosed) return;
    switch (result) {
      case Success(:final value):
        emit(
          state.copyWith(
            step: RegisterStep.otp,
            status: RegisterStatus.idle,
            challenge: value,
          ),
        );
      case Failure(:final failure):
        emit(
          state.copyWith(
            status: RegisterStatus.failure,
            message: failure.message,
          ),
        );
    }
  }

  Future<void> _onOtpResent(
    RegisterOtpResent event,
    Emitter<RegisterState> emit,
  ) async {
    if (state.step != RegisterStep.otp || state.isBusy) return;
    await _sendOtp(emit);
  }

  Future<void> _onOtpSubmitted(
    RegisterOtpSubmitted event,
    Emitter<RegisterState> emit,
  ) async {
    final challenge = state.challenge;
    if (state.step != RegisterStep.otp || state.isBusy || challenge == null) {
      return;
    }
    final code = event.code.trim();
    if (code.length != 6 || int.tryParse(code) == null) {
      emit(
        state.copyWith(
          status: RegisterStatus.failure,
          message: 'Enter the 6-digit code.',
        ),
      );
      return;
    }
    emit(state.copyWith(status: RegisterStatus.busy));
    final result = await _verification.confirmOtp(
      challenge: challenge,
      code: code,
    );
    if (isClosed) return;
    switch (result) {
      case Success():
        await _submit(emit);
      case Failure(:final failure):
        emit(
          state.copyWith(
            status: RegisterStatus.failure,
            message: failure.message,
          ),
        );
    }
  }

  Future<void> _onSubmitRetried(
    RegisterSubmitRetried event,
    Emitter<RegisterState> emit,
  ) async {
    if (state.step != RegisterStep.submitting ||
        state.status != RegisterStatus.failure) {
      return;
    }
    await _submit(emit);
  }

  Future<void> _submit(Emitter<RegisterState> emit) async {
    emit(
      state.copyWith(
        step: RegisterStep.submitting,
        status: RegisterStatus.busy,
      ),
    );
    final draft = state.draft;
    final role = draft.role!;
    final document = RegistrationDocument(
      number: draft.documentNumber,
      licenceExpiry: role == UserRole.renter ? draft.licenceExpiry : null,
      photoBytes: draft.photoBytes ?? Uint8List(0),
      photoExtension: draft.photoExtension,
    );

    final Result<bool> result;
    if (state.isGoogle) {
      final done = await _completeGoogle(
        GoogleRegistrationInput(
          role: role,
          name: draft.name,
          phone: draft.phone,
          dateOfBirth: draft.dateOfBirth!,
          document: document,
        ),
      );
      // Google accounts are already verified, nothing was mailed.
      result = done.when(
        success: (_) => const Result.success(true),
        failure: Result.failure,
      );
    } else {
      final done = await _registerWithEmail(
        RegistrationInput(
          role: role,
          name: draft.name,
          phone: draft.phone,
          email: draft.email,
          password: draft.password,
          dateOfBirth: draft.dateOfBirth!,
          document: document,
        ),
      );
      result = done.when(
        success: (outcome) => Result.success(outcome.verificationEmailSent),
        failure: Result.failure,
      );
    }
    if (isClosed) return;
    switch (result) {
      case Success(:final value):
        emit(
          state.copyWith(
            step: RegisterStep.done,
            status: RegisterStatus.idle,
            verificationEmailSent: value,
          ),
        );
      case Failure(:final failure):
        emit(
          state.copyWith(
            status: RegisterStatus.failure,
            message: failure.message,
          ),
        );
    }
    if (result case Success()) {
      unawaited(
        _linkCurrentAccount(password: state.isGoogle ? null : draft.password),
      );
    }
  }

  void _onBackPressed(RegisterBackPressed event, Emitter<RegisterState> emit) {
    if (state.isBusy) return;
    switch (state.step) {
      case RegisterStep.role || RegisterStep.done:
        return;
      case RegisterStep.details:
        emit(
          state.copyWith(
            step: RegisterStep.role,
            status: RegisterStatus.idle,
            fieldErrors: const {},
          ),
        );
      case RegisterStep.otp || RegisterStep.submitting:
        emit(
          state.copyWith(
            step: RegisterStep.details,
            status: RegisterStatus.idle,
            clearChallenge: true,
          ),
        );
    }
  }
}
