import 'package:flutter_test/flutter_test.dart';

import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/domain/services/pricing_calculator.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/discovery/domain/usecases/get_vehicle_detail.dart';
import 'package:veloce/features/discovery/presentation/bloc/car_detail_bloc.dart';

import '../../../../support/builders.dart';
import '../../support/discovery_fakes.dart';

class _FixedClock implements Clock {
  @override
  DateTime now() => testNow;
}

void main() {
  CarDetailBloc build({
    String ownerId = 'owner-1',
    DateTime? start,
    DateTime? end,
  }) {
    final repository = FakeSearchRepository(
      detailResult: Result.success(
        aVehicleDetail(vehicle: aVehicle(ownerId: ownerId)),
      ),
    );
    return CarDetailBloc(
      getDetail: GetVehicleDetail(repository),
      session: FakeAuthSession(),
      pricing: const PricingCalculator(),
      clock: _FixedClock(),
      vehicleId: 'car-1',
      initialStart: start,
      initialEnd: end,
    )..add(const CarDetailStarted());
  }

  test('computes a quote for the selected dates', () async {
    final bloc = build(
      start: testNow,
      end: testNow.add(const Duration(days: 3)),
    );
    await pumpEventQueue();
    final state = bloc.state as CarDetailLoaded;
    expect(state.quote?.days, 3);
    expect(state.quote?.dailyRateApplied, 70000);
    expect(state.canRequest, isFalse);
    bloc.add(const CarDetailTermsChanged(true));
    await pumpEventQueue();
    expect((bloc.state as CarDetailLoaded).canRequest, isTrue);
    await bloc.close();
  });

  test('an owner gets a read-only preview that cannot request', () async {
    final bloc = build(ownerId: 'renter-1');
    await pumpEventQueue();
    final state = bloc.state as CarDetailLoaded;
    expect(state.isOwner, isTrue);
    bloc.add(const CarDetailTermsChanged(true));
    await pumpEventQueue();
    expect((bloc.state as CarDetailLoaded).canRequest, isFalse);
    await bloc.close();
  });
}
