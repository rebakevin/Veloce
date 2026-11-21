import 'package:veloce/core/domain/entities/vehicle.dart';
import 'package:veloce/core/domain/entities/vehicle_photo.dart';
import 'package:veloce/core/error/result.dart';

import '../repositories/vehicle_repository.dart';

/// The main photo url of each car, keyed by vehicle id. Cars without photos,
/// or whose photos could not be read, are left out.
class FindPrimaryPhotos {
  const FindPrimaryPhotos(this._vehicles);

  final VehicleRepository _vehicles;

  Future<Map<String, String>> call(List<Vehicle> vehicles) async {
    final results = await Future.wait([
      for (final vehicle in vehicles) _vehicles.photosOf(vehicle.id),
    ]);
    final urls = <String, String>{};
    for (var i = 0; i < vehicles.length; i++) {
      final result = results[i];
      if (result is! Success<List<VehiclePhoto>> || result.value.isEmpty) {
        continue;
      }
      final photos = [...result.value]
        ..sort((a, b) => a.order.compareTo(b.order));
      urls[vehicles[i].id] =
          (photos.where((p) => p.isPrimary).firstOrNull ?? photos.first).url;
    }
    return urls;
  }
}
