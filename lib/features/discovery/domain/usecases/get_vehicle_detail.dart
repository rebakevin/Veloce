import 'package:veloce/core/error/result.dart';

import '../entities/vehicle_detail.dart';
import '../repositories/search_repository.dart';

class GetVehicleDetail {
  const GetVehicleDetail(this._repository);

  final SearchRepository _repository;

  Future<Result<VehicleDetail>> call(String vehicleId) =>
      _repository.detail(vehicleId);
}
