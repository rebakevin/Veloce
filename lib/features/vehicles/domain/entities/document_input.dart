import 'package:equatable/equatable.dart';
import 'package:veloce/core/domain/entities/document_photo.dart';
import 'package:veloce/core/domain/enums/document_kind.dart';

/// What the owner typed when adding or replacing one vehicle paper.
class DocumentInput extends Equatable {
  const DocumentInput({
    required this.kind,
    required this.number,
    required this.plate,
    required this.expiry,
    this.photo,
  });

  final DocumentKind kind;
  final String number;
  final String plate;
  final DateTime? expiry;

  /// A newly picked photo; null keeps the photo the car already has.
  final DocumentPhoto? photo;

  @override
  List<Object?> get props => [kind, number, plate, expiry, photo];
}
