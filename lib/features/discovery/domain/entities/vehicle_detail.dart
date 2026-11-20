import 'package:equatable/equatable.dart';

import 'package:veloce/core/domain/entities/calendar_block.dart';
import 'package:veloce/core/domain/entities/user_account.dart';
import 'package:veloce/core/domain/entities/vehicle.dart';
import 'package:veloce/core/domain/entities/vehicle_photo.dart';

import 'vehicle_card_data.dart';

/// Everything the car detail page needs in one read.
class VehicleDetail extends Equatable {
  const VehicleDetail({
    required this.vehicle,
    required this.photos,
    required this.owner,
    required this.blocks,
  });

  final Vehicle vehicle;
  final List<VehiclePhoto> photos;
  final UserAccount owner;
  final List<CalendarBlock> blocks;

  String? get primaryPhotoUrl {
    if (photos.isEmpty) return null;
    for (final photo in photos) {
      if (photo.isPrimary) return photo.url;
    }
    return photos.first.url;
  }

  VehicleCardData get card =>
      VehicleCardData(vehicle: vehicle, photoUrl: primaryPhotoUrl);

  @override
  List<Object?> get props => [vehicle, photos, owner, blocks];
}
