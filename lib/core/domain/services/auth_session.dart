import '../enums/user_role.dart';

/// Who is signed in. Cubits use this instead of Firebase Auth directly.
abstract interface class AuthSession {
  String? get currentUserId;

  UserRole? get role;

  /// Emits whenever the signed-in user or their role changes.
  Stream<void> get changes;
}
