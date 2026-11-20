import 'package:equatable/equatable.dart';

import 'package:veloce/core/domain/entities/vehicle.dart';

/// A car as shown in a list: the vehicle plus its primary photo.
class VehicleCardData extends Equatable {
  const VehicleCardData({required this.vehicle, this.photoUrl});

  final Vehicle vehicle;
  final String? photoUrl;

  @override
  List<Object?> get props => [vehicle, photoUrl];
}
