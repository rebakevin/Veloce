import 'package:equatable/equatable.dart';
import 'package:veloce/core/domain/entities/document_photo.dart';
import 'package:veloce/core/validation/validators.dart';

/// Editable profile fields. [newPhoto] replaces the avatar when set; `null`
/// keeps the current one.
class ProfileUpdate extends Equatable {
  const ProfileUpdate({
    required this.name,
    required this.phone,
    required this.dateOfBirth,
    this.newPhoto,
  });

  final String name;
  final String phone;
  final DateTime dateOfBirth;
  final DocumentPhoto? newPhoto;

  /// First problem as a user-facing message, or `null` when valid.
  String? validate({required DateTime now}) {
    return Validators.requiredText(name, field: 'Name') ??
        Validators.phone(phone) ??
        Validators.dateOfBirth(dateOfBirth, now: now);
  }

  @override
  List<Object?> get props => [name, phone, dateOfBirth, newPhoto];
}
