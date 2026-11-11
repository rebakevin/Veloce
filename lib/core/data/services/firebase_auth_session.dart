import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/enums/user_role.dart';
import '../../domain/services/auth_session.dart';
import 'user_lookup.dart';

/// [AuthSession] backed by Firebase Auth plus the role stored on `users/{uid}`.
/// Phase 1 builds `AuthBloc` on top of this.
class FirebaseAuthSession implements AuthSession {
  FirebaseAuthSession({required FirebaseAuth auth, required this._users})
    : _auth = auth {
    _userId = auth.currentUser?.uid;
    _subscription = auth.authStateChanges().listen(_onAuthChanged);
    unawaited(_loadRole());
  }

  final FirebaseAuth _auth;
  final UserLookup _users;
  final StreamController<void> _changes = StreamController<void>.broadcast();
  late final StreamSubscription<User?> _subscription;

  String? _userId;
  UserRole? _role;

  @override
  String? get currentUserId => _userId;

  @override
  UserRole? get role => _role;

  @override
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  @override
  Stream<void> get changes => _changes.stream;

  Future<void> _onAuthChanged(User? user) async {
    _userId = user?.uid;
    _role = null;
    if (user == null) _users.clear();
    _changes.add(null);
    await _loadRole();
  }

  Future<void> _loadRole() async {
    final id = _userId;
    if (id == null) return;
    final result = await _users.byId(id);
    if (_userId != id) return;
    _role = result.when(success: (user) => user.role, failure: (_) => null);
    _changes.add(null);
  }

  /// Re-reads the role, e.g. right after registration created the profile.
  Future<void> refresh() => _loadRole();

  Future<void> dispose() async {
    await _subscription.cancel();
    await _changes.close();
  }
}
