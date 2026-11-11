import 'package:veloce/core/domain/entities/user_account.dart';
import 'package:veloce/core/domain/enums/auth_provider_kind.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';

import '../entities/linked_account.dart';
import '../repositories/auth_repository.dart';
import '../repositories/linked_account_store.dart';
import '../repositories/registration_store.dart';

/// Links the signed-in account to this device. Email accounts need their
/// [password] (kept in secure storage); Google accounts store no credential.
class LinkCurrentAccount {
  const LinkCurrentAccount({
    required this._auth,
    required this._profiles,
    required this._store,
  });

  final AuthRepository _auth;
  final RegistrationStore _profiles;
  final LinkedAccountStore _store;

  Future<Result<LinkedAccount>> call({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) {
      return const Result.failure(ValidationFailure('Sign in first.'));
    }
    final isEmail = user.provider == AuthProviderKind.password;
    if (isEmail && (password == null || password.isEmpty)) {
      return const Result.failure(
        ValidationFailure('Enter your password to link this account.'),
      );
    }

    final found = await _profiles.findProfile(user.uid);
    if (found case Failure(:final failure)) return Result.failure(failure);
    final profile = (found as Success<UserAccount?>).value;
    if (profile == null) return const Result.failure(NotFoundFailure());

    final account = LinkedAccount(
      uid: user.uid,
      email: user.email,
      name: profile.name,
      role: profile.role,
      authType: user.provider,
    );
    final saved = await _store.save(
      account,
      password: isEmail ? password : null,
    );
    return switch (saved) {
      Failure(:final failure) => Result.failure(failure),
      Success() => Result.success(account),
    };
  }
}
