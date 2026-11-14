import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:veloce/core/domain/enums/auth_provider_kind.dart';

import '../domain/entities/auth_user.dart';

/// The only class that talks to Firebase Auth and Google Sign-In. It throws SDK
/// exceptions; `FirebaseAuthRepository` turns them into results.
class FirebaseAuthDataSource {
  FirebaseAuthDataSource({
    required this._auth,
    GoogleSignIn? googleSignIn,
    this._serverClientId,
  }) : _google = googleSignIn ?? GoogleSignIn.instance;

  static const Duration _timeout = Duration(seconds: 30);

  final FirebaseAuth _auth;
  final GoogleSignIn _google;
  final String? _serverClientId;

  /// google_sign_in 7 needs one `initialize` before any other call. On Android
  /// the server client id comes from google-services.json when omitted.
  Future<void>? _googleReady;

  AuthUser? get currentUser => _map(_auth.currentUser);

  Stream<AuthUser?> userChanges() => _auth.userChanges().map(_map);

  Future<AuthUser> createEmailUser({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth
        .createUserWithEmailAndPassword(email: email, password: password)
        .timeout(_timeout);
    final user = credential.user!;
    await user.updateDisplayName(displayName);
    return _map(user)!;
  }

  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth
        .signInWithEmailAndPassword(email: email, password: password)
        .timeout(_timeout);
    return _map(credential.user)!;
  }

  Future<AuthUser> signInWithGoogle() async {
    await _ensureGoogleReady();
    final account = await _google.authenticate();
    return _signInToFirebase(account);
  }

  /// `null` when the platform cannot restore a Google session without UI.
  Future<AuthUser?> signInWithGoogleSilently() async {
    await _ensureGoogleReady();
    final attempt = _google.attemptLightweightAuthentication();
    final account = attempt == null ? null : await attempt;
    if (account == null) return null;
    return _signInToFirebase(account);
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email).timeout(_timeout);

  Future<void> sendEmailVerification() =>
      _requireUser().sendEmailVerification().timeout(_timeout);

  Future<AuthUser> reloadUser() async {
    final user = _requireUser();
    await user.reload().timeout(_timeout);
    return _map(_auth.currentUser)!;
  }

  Future<void> reauthenticate({String? password}) async {
    final user = _requireUser();
    final AuthCredential credential;
    if (_map(user)!.provider == AuthProviderKind.google) {
      await _ensureGoogleReady();
      final idToken = (await _google.authenticate()).authentication.idToken;
      if (idToken == null) {
        throw FirebaseAuthException(code: 'invalid-credential');
      }
      credential = GoogleAuthProvider.credential(idToken: idToken);
    } else {
      credential = EmailAuthProvider.credential(
        email: user.email ?? '',
        password: password ?? '',
      );
    }
    await user.reauthenticateWithCredential(credential).timeout(_timeout);
  }

  Future<void> deleteCurrentUser() => _requireUser().delete().timeout(_timeout);

  Future<void> signOut() async {
    await _auth.signOut();
    await _ensureGoogleReady();
    await _google.signOut();
  }

  /// Firebase only, so Google can silently sign the account back in.
  Future<void> suspendSession() => _auth.signOut();

  Future<AuthUser> _signInToFirebase(GoogleSignInAccount account) async {
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw FirebaseAuthException(code: 'invalid-credential');
    }
    final credential = await _auth
        .signInWithCredential(GoogleAuthProvider.credential(idToken: idToken))
        .timeout(_timeout);
    return _map(credential.user)!;
  }

  Future<void> _ensureGoogleReady() =>
      _googleReady ??= _google.initialize(serverClientId: _serverClientId);

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) throw FirebaseAuthException(code: 'no-current-user');
    return user;
  }

  AuthUser? _map(User? user) {
    if (user == null) return null;
    final isGoogle = user.providerData.any(
      (info) => info.providerId == GoogleAuthProvider.PROVIDER_ID,
    );
    return AuthUser(
      uid: user.uid,
      email: user.email ?? '',
      emailVerified: user.emailVerified,
      displayName: user.displayName,
      provider: isGoogle ? AuthProviderKind.google : AuthProviderKind.password,
    );
  }
}
