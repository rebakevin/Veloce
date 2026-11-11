import 'package:equatable/equatable.dart';

import 'package:veloce/core/domain/enums/auth_provider_kind.dart';

/// The signed-in Firebase identity, stripped of SDK types.
class AuthUser extends Equatable {
  const AuthUser({
    required this.uid,
    required this.email,
    required this.emailVerified,
    required this.displayName,
    required this.provider,
  });

  final String uid;
  final String email;
  final bool emailVerified;
  final String? displayName;
  final AuthProviderKind provider;

  @override
  List<Object?> get props => [uid, email, emailVerified, displayName, provider];
}
