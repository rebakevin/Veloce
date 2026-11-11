import 'package:veloce/core/domain/enums/auth_provider_kind.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';

import '../entities/auth_user.dart';
import '../entities/new_profile.dart';
import '../entities/registration_input.dart';
import '../entities/registration_outcome.dart';
import '../repositories/auth_repository.dart';
import '../repositories/registration_store.dart';
import 'submit_identity_document.dart';

/// Creates an email account end to end (TECHNICAL.md §6.1): validate, upload
/// and verify the document, create the Auth user, write the profile in one
/// atomic batch, then send the verification email. Run it after the OTP step.
///
/// The document is checked before the Auth user exists, so a failed check
/// leaves nothing behind. If a later step fails, the uploaded photo and the
/// Auth user are removed again (best effort) and the failure is returned.
class RegisterWithEmail {
  const RegisterWithEmail({
    required this._auth,
    required this._store,
    required this._submitDocument,
    required this._clock,
  });

  final AuthRepository _auth;
  final RegistrationStore _store;
  final SubmitIdentityDocument _submitDocument;
  final Clock _clock;

  Future<Result<RegistrationOutcome>> call(RegistrationInput input) async {
    final problem = input.validate(now: _clock.now());
    if (problem != null) return Result.failure(ValidationFailure(problem));

    final submitted = await _submitDocument(input.document);
    if (submitted case Failure(:final failure)) return Result.failure(failure);
    final photoUrl = (submitted as Success<String>).value;

    final email = input.email.trim();
    final name = input.name.trim();
    final created = await _auth.createEmailUser(
      email: email,
      password: input.password,
      displayName: name,
    );
    if (created case Failure(:final failure)) {
      await _submitDocument.discard(photoUrl);
      return Result.failure(failure);
    }
    final user = (created as Success<AuthUser>).value;

    final written = await _store.createProfile(
      NewProfile(
        uid: user.uid,
        role: input.role,
        name: name,
        email: email,
        phone: input.phone.trim(),
        dateOfBirth: input.dateOfBirth,
        authProvider: AuthProviderKind.password,
        documentNumber: input.document.number.trim(),
        documentPhotoUrl: photoUrl,
        licenceExpiry: input.document.licenceExpiry,
      ),
    );
    if (written case Failure(:final failure)) {
      await _auth.deleteCurrentUser();
      await _submitDocument.discard(photoUrl);
      return Result.failure(failure);
    }

    // The account is complete at this point, so a mail failure is reported in
    // the outcome and the verify-email page offers a resend.
    final mailed = await _auth.sendEmailVerification();
    return Result.success(
      RegistrationOutcome(user: user, verificationEmailSent: mailed is Success),
    );
  }
}
