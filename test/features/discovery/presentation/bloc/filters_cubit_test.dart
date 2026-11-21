import 'package:flutter_test/flutter_test.dart';

import 'package:veloce/core/domain/enums/transmission.dart';
import 'package:veloce/core/domain/enums/vehicle_type.dart';
import 'package:veloce/features/discovery/presentation/bloc/filters_cubit.dart';

void main() {
  test('counts every active filter and resets them', () {
    final cubit = FiltersCubit();
    expect(cubit.activeCount, 0);
    cubit
      ..minPriceChanged(30000)
      ..typeChanged(VehicleType.suv)
      ..transmissionChanged(Transmission.automatic)
      ..seatsChanged(7);
    expect(cubit.activeCount, 4);
    expect(cubit.state.type, VehicleType.suv);
    cubit.reset();
    expect(cubit.activeCount, 0);
  });

  test('clearing a value removes it from the count', () {
    final cubit = FiltersCubit();
    cubit
      ..minPriceChanged(30000)
      ..minPriceChanged(null);
    expect(cubit.activeCount, 0);
    expect(cubit.state.minPrice, isNull);
  });

  test('flags a minimum price above the maximum', () {
    final cubit = FiltersCubit()
      ..minPriceChanged(200000)
      ..maxPriceChanged(100000);
    expect(cubit.state.hasValidPriceRange, isFalse);
    cubit.maxPriceChanged(250000);
    expect(cubit.state.hasValidPriceRange, isTrue);
  });
}
