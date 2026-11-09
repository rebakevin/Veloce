import 'package:equatable/equatable.dart';

import '../enums/document_kind.dart';

/// A private vehicle paper. Doc id is the [DocumentKind] key.
class VehicleDocument extends Equatable {
  const VehicleDocument({
    required this.kind,
    required this.vehicleId,
    required this.number,
    required this.expiry,
    required this.photoUrl,
    required this.verified,
  });

  final DocumentKind kind;
  final String vehicleId;
  final String number;
  final DateTime expiry;
  final String photoUrl;
  final bool verified;

  VehicleDocument copyWith({
    DocumentKind? kind,
    String? vehicleId,
    String? number,
    DateTime? expiry,
    String? photoUrl,
    bool? verified,
  }) {
    return VehicleDocument(
      kind: kind ?? this.kind,
      vehicleId: vehicleId ?? this.vehicleId,
      number: number ?? this.number,
      expiry: expiry ?? this.expiry,
      photoUrl: photoUrl ?? this.photoUrl,
      verified: verified ?? this.verified,
    );
  }

  @override
  List<Object?> get props => [
    kind,
    vehicleId,
    number,
    expiry,
    photoUrl,
    verified,
  ];
}
