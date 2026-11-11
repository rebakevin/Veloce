import 'package:equatable/equatable.dart';

import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/validation/validators.dart';

import 'registration_document.dart';

/// What a first-time Google user adds after signing in. Name and email come
/// from the Google account; [name] only overrides the display name.
class GoogleRegistrationInput extends Equatable {
  const GoogleRegistrationInput({
    required this.role,
    required this.phone,
    required this.dateOfBirth,
    required this.document,
    this.name,
  });

  final UserRole role;
  final String? name;
  final String phone;
  final DateTime dateOfBirth;
  final RegistrationDocument document;

  /// First problem as a user-facing message, or `null` when valid.
  String? validate({required DateTime now}) {
    final override = name;
    return (override == null
            ? null
            : Validators.requiredText(override, field: 'Name')) ??
        Validators.phone(phone) ??
        Validators.dateOfBirth(dateOfBirth, now: now) ??
        document.validate(role: role, now: now);
  }

  @override
  List<Object?> get props => [role, name, phone, dateOfBirth, document];
}
