import 'package:equatable/equatable.dart';
import 'package:veloce/core/domain/entities/document_photo.dart';
import 'package:veloce/core/validation/validators.dart';

/// A renter's licence to add or replace. [photo] may be `null` only when a
/// licence already exists, to keep its photo.
class LicenceSubmission extends Equatable {
  const LicenceSubmission({
    required this.number,
    required this.expiry,
    this.photo,
  });

  final String number;
  final DateTime expiry;
  final DocumentPhoto? photo;

  /// First problem as a user-facing message, or `null` when valid.
  String? validate({required DateTime now}) {
    return Validators.licenceNumber(number) ??
        Validators.licenceExpiry(expiry, now: now);
  }

  @override
  List<Object?> get props => [number, expiry, photo];
}
