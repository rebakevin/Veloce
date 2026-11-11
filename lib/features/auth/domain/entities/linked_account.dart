import 'package:equatable/equatable.dart';

import 'package:veloce/core/domain/enums/auth_provider_kind.dart';
import 'package:veloce/core/domain/enums/user_role.dart';

/// An account linked to this device for the account switcher (spec §8.2).
/// The stored credential, if any, is not part of this value.
class LinkedAccount extends Equatable {
  const LinkedAccount({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.authType,
  });

  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final AuthProviderKind authType;

  @override
  List<Object?> get props => [uid, email, name, role, authType];
}
