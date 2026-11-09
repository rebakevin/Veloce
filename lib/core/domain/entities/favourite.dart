import 'package:equatable/equatable.dart';

/// A vehicle saved by a renter. Doc id is the vehicle id.
class Favourite extends Equatable {
  const Favourite({
    required this.vehicleId,
    required this.userId,
    required this.createdAt,
  });

  final String vehicleId;
  final String userId;
  final DateTime createdAt;

  Favourite copyWith({String? vehicleId, String? userId, DateTime? createdAt}) {
    return Favourite(
      vehicleId: vehicleId ?? this.vehicleId,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [vehicleId, userId, createdAt];
}
