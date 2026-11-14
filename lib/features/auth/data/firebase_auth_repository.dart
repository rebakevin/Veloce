import 'package:veloce/core/error/result.dart';

import '../domain/entities/auth_user.dart';
import '../domain/repositories/auth_repository.dart';
import 'auth_failure_mapper.dart';
import 'firebase_auth_data_source.dart';

/// [AuthRepository] over [FirebaseAuthDataSource]: every SDK exception becomes
/// a [Failure] through [mapAuthFailure].
class FirebaseAuthRepository implements AuthRepository {
  const FirebaseAuthRepository(this._source);

  final FirebaseAuthDataSource _source;

  @override
  AuthUser? get currentUser => _source.currentUser;

  @override
  Stream<AuthUser?> get userChanges => _source.userChanges();

  @override
  Future<Result<AuthUser>> createEmailUser({
    required String email,
    required String password,
    required String displayName,
  }) => _guard(
    () => _source.createEmailUser(
      email: email,
      password: password,
      displayName: displayName,
    ),
  );

  @override
  Future<Result<AuthUser>> signInWithEmail({
    required String email,
    required String password,
  }) => _guard(() => _source.signInWithEmail(email: email, password: password));

  @override
  Future<Result<AuthUser>> signInWithGoogle() =>
      _guard(_source.signInWithGoogle);

  @override
  Future<Result<AuthUser?>> signInWithGoogleSilently() =>
      _guard(_source.signInWithGoogleSilently);

  @override
  Future<Result<void>> sendPasswordReset(String email) =>
      _guard(() => _source.sendPasswordReset(email));

  @override
  Future<Result<void>> sendEmailVerification() =>
      _guard(_source.sendEmailVerification);

  @override
  Future<Result<AuthUser>> reloadUser() => _guard(_source.reloadUser);

  @override
  Future<Result<void>> reauthenticate({String? password}) =>
      _guard(() => _source.reauthenticate(password: password));

  @override
  Future<Result<void>> deleteCurrentUser() => _guard(_source.deleteCurrentUser);

  @override
  Future<Result<void>> signOut() => _guard(_source.signOut);

  @override
  Future<Result<void>> suspendSession() => _guard(_source.suspendSession);

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Result.success(await action());
    } on Object catch (error, stackTrace) {
      return Result.failure(mapAuthFailure(error, stackTrace));
    }
  }
}
