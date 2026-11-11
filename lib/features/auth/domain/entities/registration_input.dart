import 'package:equatable/equatable.dart';

import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/validation/validators.dart';

import 'registration_document.dart';

/// Everything the multi-step email registration collects.
class RegistrationInput extends Equatable {
  const RegistrationInput({
    required this.role,
    required this.name,
    required this.phone,
    required this.email,
    required this.password,
    required this.dateOfBirth,
    required this.document,
  });

  final UserRole role;
  final String name;
  final String phone;
  final String email;
  final String password;
  final DateTime dateOfBirth;
  final RegistrationDocument document;

  /// First problem as a user-facing message, or `null` when valid.
  String? validate({required DateTime now}) {
    return Validators.requiredText(name, field: 'Name') ??
        Validators.phone(phone) ??
        Validators.email(email) ??
        Validators.password(password) ??
        Validators.dateOfBirth(dateOfBirth, now: now) ??
        document.validate(role: role, now: now);
  }

  @override
  List<Object?> get props => [
    role,
    name,
    phone,
    email,
    password,
    dateOfBirth,
    document,
  ];
}
