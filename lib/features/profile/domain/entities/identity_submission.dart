import 'package:equatable/equatable.dart';
import 'package:veloce/core/domain/entities/document_photo.dart';
import 'package:veloce/core/validation/validators.dart';

/// An owner's National ID to replace. [photo] may be `null` to keep the
/// stored photo.
class IdentitySubmission extends Equatable {
  const IdentitySubmission({required this.nationalIdNumber, this.photo});

  final String nationalIdNumber;
  final DocumentPhoto? photo;

  /// First problem as a user-facing message, or `null` when valid.
  String? validate() => Validators.nationalId(nationalIdNumber);

  @override
  List<Object?> get props => [nationalIdNumber, photo];
}
