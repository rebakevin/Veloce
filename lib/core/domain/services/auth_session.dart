import '../enums/user_role.dart';

/// Who is signed in. Cubits use this instead of Firebase Auth directly.
abstract interface class AuthSession {
  String? get currentUserId;

  UserRole? get role;

  /// Whether the signed-in user has confirmed their email. `false` when signed
  /// out. Google users are verified by default.
  bool get isEmailVerified;

  /// Emits whenever the signed-in user or their role changes.
  Stream<void> get changes;
}
