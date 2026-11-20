import 'package:equatable/equatable.dart';
import 'package:veloce/core/domain/entities/vehicle.dart';
import 'package:veloce/core/domain/entities/vehicle_document.dart';
import 'package:veloce/core/domain/entities/vehicle_photo.dart';

class PublishRequest extends Equatable {
  const PublishRequest({
    required this.vehicle,
    required this.photos,
    required this.documents,
  });

  final Vehicle vehicle;
  final List<VehiclePhoto> photos;
  final List<VehicleDocument> documents;

  @override
  List<Object?> get props => [vehicle, photos, documents];
}
