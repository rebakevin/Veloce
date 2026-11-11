import 'package:veloce/core/domain/enums/auth_provider_kind.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';

import '../entities/auth_user.dart';
import '../entities/google_registration_input.dart';
import '../entities/new_profile.dart';
import '../repositories/auth_repository.dart';
import '../repositories/registration_store.dart';
import 'submit_identity_document.dart';

/// Writes the profile of a Google user who signed in for the first time, after
/// role choice and the document step. Google users are email-verified, so no
/// verification mail is sent. A failure keeps the Google session so the user
/// can retry; the Auth user is not deleted.
class CompleteGoogleRegistration {
  const CompleteGoogleRegistration({
    required this._auth,
    required this._store,
    required this._submitDocument,
    required this._clock,
  });

  final AuthRepository _auth;
  final RegistrationStore _store;
  final SubmitIdentityDocument _submitDocument;
  final Clock _clock;

  Future<Result<AuthUser>> call(GoogleRegistrationInput input) async {
    final user = _auth.currentUser;
    if (user == null || user.provider != AuthProviderKind.google) {
      return const Result.failure(
        ValidationFailure('Sign in with Google to continue.'),
      );
    }
    final problem = input.validate(now: _clock.now());
    if (problem != null) return Result.failure(ValidationFailure(problem));

    final submitted = await _submitDocument(input.document);
    if (submitted case Failure(:final failure)) return Result.failure(failure);
    final photoUrl = (submitted as Success<String>).value;

    final name = (input.name ?? user.displayName ?? '').trim();
    final written = await _store.createProfile(
      NewProfile(
        uid: user.uid,
        role: input.role,
        name: name.isEmpty ? user.email.split('@').first : name,
        email: user.email,
        phone: input.phone.trim(),
        dateOfBirth: input.dateOfBirth,
        authProvider: AuthProviderKind.google,
        documentNumber: input.document.number.trim(),
        documentPhotoUrl: photoUrl,
        licenceExpiry: input.document.licenceExpiry,
      ),
    );
    if (written case Failure(:final failure)) {
      await _submitDocument.discard(photoUrl);
      return Result.failure(failure);
    }
    return Result.success(user);
  }
}
