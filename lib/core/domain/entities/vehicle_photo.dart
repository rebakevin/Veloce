import 'package:equatable/equatable.dart';

/// A photo of a vehicle.
class VehiclePhoto extends Equatable {
  const VehiclePhoto({
    required this.id,
    required this.vehicleId,
    required this.url,
    required this.order,
    required this.isPrimary,
  });

  final String id;
  final String vehicleId;
  final String url;
  final int order;
  final bool isPrimary;

  VehiclePhoto copyWith({
    String? id,
    String? vehicleId,
    String? url,
    int? order,
    bool? isPrimary,
  }) {
    return VehiclePhoto(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      url: url ?? this.url,
      order: order ?? this.order,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }

  @override
  List<Object?> get props => [id, vehicleId, url, order, isPrimary];
}
