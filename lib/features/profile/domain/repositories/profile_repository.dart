import 'package:veloce/core/domain/entities/contact.dart';
import 'package:veloce/core/domain/entities/licence.dart';
import 'package:veloce/core/domain/entities/owner_identity.dart';
import 'package:veloce/core/domain/entities/payout_method.dart';
import 'package:veloce/core/domain/entities/user_account.dart';
import 'package:veloce/core/error/result.dart';

import '../entities/identity_submission.dart';
import '../entities/licence_submission.dart';
import '../entities/profile_update.dart';
import '../entities/public_profile.dart';

/// The signed-in user's profile and private documents, plus read-only public
/// profiles of other users. "Own" methods act on `AuthSession.currentUserId`
/// and fail with a `PermissionFailure` when nobody is signed in. Inputs are
/// validated before any upload or write, and a `ValidationFailure` carries the
/// message for the form.
abstract interface class ProfileRepository {
  Future<Result<UserAccount>> getProfile();

  Stream<Result<UserAccount>> watchProfile();

  Future<Result<Contact>> getContact();

  /// Updates name and photo on `users/{uid}` and phone and date of birth on
  /// `private/contact` in one atomic write. A new photo goes to storage first.
  Future<Result<void>> updateProfile(ProfileUpdate update);

  /// `null` when the renter has no licence yet.
  Future<Result<Licence?>> getLicence();

  /// Adds or replaces the licence after the simulated verification passes.
  /// Renters only.
  Future<Result<Licence>> saveLicence(LicenceSubmission submission);

  /// `null` when the owner has no identity document yet.
  Future<Result<OwnerIdentity?>> getIdentity();

  /// Replaces the National ID after the simulated verification passes. Owners
  /// only.
  Future<Result<OwnerIdentity>> replaceIdentity(IdentitySubmission submission);

  /// `null` when no MoMo number is saved yet. Owners only.
  Future<Result<PayoutMethod?>> getPayout();

  /// Saves the MoMo number, typed as the 9 digits after the leading 0.
  Future<Result<PayoutMethod>> savePayout(String momoNumber);

  /// Public view of any user. Never includes contact details.
  Future<Result<PublicProfile>> getPublicProfile(String userId);
}
