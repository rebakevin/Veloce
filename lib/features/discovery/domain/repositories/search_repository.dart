import 'package:veloce/core/error/result.dart';

import '../entities/search_query.dart';
import '../entities/vehicle_card_data.dart';
import '../entities/vehicle_detail.dart';
import '../entities/vehicle_filters.dart';

/// Published-car search and detail reads (TECHNICAL.md §4.5).
abstract interface class SearchRepository {
  Future<Result<List<VehicleCardData>>> search({
    required SearchQuery query,
    required VehicleFilters filters,
  });

  Future<Result<VehicleDetail>> detail(String vehicleId);

  Future<Result<List<VehicleCardData>>> ownerCars(String ownerId);
}
