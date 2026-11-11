import 'package:equatable/equatable.dart';

import 'package:veloce/core/domain/enums/auth_provider_kind.dart';
import 'package:veloce/core/domain/enums/user_role.dart';

/// A validated, uploaded and verified profile ready to be written as
/// `users/{uid}` plus its private documents. Built by the registration use
/// cases, consumed by [RegistrationStore].
class NewProfile extends Equatable {
  const NewProfile({
    required this.uid,
    required this.role,
    required this.name,
    required this.email,
    required this.phone,
    required this.dateOfBirth,
    required this.authProvider,
    required this.documentNumber,
    required this.documentPhotoUrl,
    this.licenceExpiry,
  });

  final String uid;
  final UserRole role;
  final String name;
  final String email;
  final String phone;
  final DateTime dateOfBirth;
  final AuthProviderKind authProvider;

  /// Licence number (renter) or National ID number (owner).
  final String documentNumber;
  final String documentPhotoUrl;

  /// Set for renters only.
  final DateTime? licenceExpiry;

  @override
  List<Object?> get props => [
    uid,
    role,
    name,
    email,
    phone,
    dateOfBirth,
    authProvider,
    documentNumber,
    documentPhotoUrl,
    licenceExpiry,
  ];
}
