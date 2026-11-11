import 'package:veloce/core/domain/entities/user_account.dart';
import 'package:veloce/core/error/result.dart';

import '../entities/new_profile.dart';

/// Reads and creates the `users/{uid}` profile of a signed-in user.
abstract interface class RegistrationStore {
  /// The profile, or `null` when the user has none yet (first Google sign-in).
  Future<Result<UserAccount?>> findProfile(String uid);

  /// Writes `users/{uid}`, `private/contact`, `private/licence` or
  /// `private/identity` and a registration audit entry in one atomic write.
  Future<Result<void>> createProfile(NewProfile profile);
}
