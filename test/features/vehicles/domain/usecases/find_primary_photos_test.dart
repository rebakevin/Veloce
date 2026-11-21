import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/entities/vehicle_photo.dart';
import 'package:veloce/features/vehicles/domain/usecases/find_primary_photos.dart';

import '../builders.dart';

VehiclePhoto _photo(String url, int order, {bool primary = false}) =>
    VehiclePhoto(
      id: url,
      vehicleId: 'car-1',
      url: url,
      order: order,
      isPrimary: primary,
    );

void main() {
  test('the photo flagged primary is chosen', () async {
    final repository = FakeVehicleRepository()
      ..photos['car-1'] = [_photo('a', 0), _photo('b', 1, primary: true)];

    final urls = await FindPrimaryPhotos(repository)([aVehicle()]);

    expect(urls, {'car-1': 'b'});
  });

  test('without a primary flag the first photo is chosen', () async {
    final repository = FakeVehicleRepository()
      ..photos['car-1'] = [_photo('b', 1), _photo('a', 0)];

    final urls = await FindPrimaryPhotos(repository)([aVehicle()]);

    expect(urls, {'car-1': 'a'});
  });

  test('a car without photos is left out', () async {
    final urls = await FindPrimaryPhotos(FakeVehicleRepository())([aVehicle()]);

    expect(urls, isEmpty);
  });
}
