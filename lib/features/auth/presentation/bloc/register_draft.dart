import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import 'package:veloce/core/domain/enums/user_role.dart';

/// What the user has typed so far across the register steps.
class RegisterDraft extends Equatable {
  const RegisterDraft({
    this.role,
    this.name = '',
    this.phone = '',
    this.email = '',
    this.password = '',
    this.dateOfBirth,
    this.documentNumber = '',
    this.licenceExpiry,
    this.photoBytes,
    this.photoExtension = 'jpg',
  });

  final UserRole? role;
  final String name;
  final String phone;
  final String email;
  final String password;
  final DateTime? dateOfBirth;

  /// Driving licence number (renter) or National ID (owner).
  final String documentNumber;
  final DateTime? licenceExpiry;
  final Uint8List? photoBytes;
  final String photoExtension;

  @override
  List<Object?> get props => [
    role,
    name,
    phone,
    email,
    password,
    dateOfBirth,
    documentNumber,
    licenceExpiry,
    photoBytes,
    photoExtension,
  ];
}
