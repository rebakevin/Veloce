import 'package:flutter_test/flutter_test.dart';

import 'package:veloce/core/domain/enums/vehicle_type.dart';
import 'package:veloce/features/discovery/domain/entities/search_query.dart';
import 'package:veloce/features/discovery/domain/entities/vehicle_filters.dart';
import 'package:veloce/features/discovery/domain/usecases/search_vehicles.dart';

import '../../../support/builders.dart';
import '../support/discovery_fakes.dart';

void main() {
  final query = SearchQuery(
    start: testNow,
    end: testNow.add(const Duration(days: 3)),
    typeChip: VehicleType.hatchback,
  );

  test('keeps the home chip when no type filter is set', () async {
    final repository = FakeSearchRepository();
    await SearchVehicles(repository)(
      query: query,
      filters: VehicleFilters.none,
    );
    expect(repository.lastQuery!.typeChip, VehicleType.hatchback);
  });

  test('a type filter replaces the home chip', () async {
    final repository = FakeSearchRepository();
    await SearchVehicles(repository)(
      query: query,
      filters: const VehicleFilters(type: VehicleType.suv),
    );
    expect(repository.lastQuery!.typeChip, isNull);
    expect(repository.lastFilters!.type, VehicleType.suv);
  });
}
