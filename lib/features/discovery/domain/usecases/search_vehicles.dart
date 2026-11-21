import 'package:veloce/core/error/result.dart';

import '../entities/search_query.dart';
import '../entities/vehicle_card_data.dart';
import '../entities/vehicle_filters.dart';
import '../repositories/search_repository.dart';

class SearchVehicles {
  const SearchVehicles(this._repository);

  final SearchRepository _repository;

  Future<Result<List<VehicleCardData>>> call({
    required SearchQuery query,
    required VehicleFilters filters,
  }) => _repository.search(
    // An explicit type filter replaces the home chip so the two cannot clash.
    query: filters.type == null ? query : query.copyWith(clearTypeChip: true),
    filters: filters,
  );
}
