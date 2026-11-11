import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/validation/validators.dart';

/// The identity document collected at sign-up: a driving licence for a renter
/// (number, expiry, photo) or a National ID for an owner (number, photo).
class RegistrationDocument extends Equatable {
  const RegistrationDocument({
    required this.number,
    required this.photoBytes,
    required this.photoExtension,
    this.licenceExpiry,
  });

  final String number;

  /// Only used for a renter's licence.
  final DateTime? licenceExpiry;
  final Uint8List photoBytes;
  final String photoExtension;

  /// First problem as a user-facing message, or `null` when valid.
  String? validate({required UserRole role, required DateTime now}) {
    return switch (role) {
      UserRole.renter =>
        Validators.licenceNumber(number) ??
            Validators.licenceExpiry(licenceExpiry, now: now) ??
            _photoProblem(),
      UserRole.owner => Validators.nationalId(number) ?? _photoProblem(),
    };
  }

  String? _photoProblem() =>
      photoBytes.isEmpty ? 'Add a photo of your document.' : null;

  @override
  List<Object?> get props => [
    number,
    licenceExpiry,
    photoBytes,
    photoExtension,
  ];
}
