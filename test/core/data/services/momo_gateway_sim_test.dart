import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/data/services/momo_gateway_sim.dart';
import 'package:veloce/core/domain/services/momo_gateway.dart';
import 'package:veloce/core/error/result.dart';

void main() {
  late MomoGatewaySim gateway;

  Future<Result<MomoReceipt>> charge(String key) => gateway.charge(
    momoNumber: '788123456',
    amount: 100000,
    bookingReference: 'VLC-0001',
    idempotencyKey: key,
  );

  setUp(() => gateway = MomoGatewaySim());

  test('a retry with the same key returns the first receipt', () async {
    final first = (await charge('booking-1') as Success<MomoReceipt>).value;
    final again = (await charge('booking-1') as Success<MomoReceipt>).value;

    expect(again, same(first));
    expect(first.reference, 'MOMO-VLC-0001');
  });

  test('a failed charge is not remembered, so the retry can succeed', () async {
    gateway.shouldSucceed = false;
    expect(await charge('booking-1'), isA<Failure<MomoReceipt>>());

    gateway.shouldSucceed = true;
    expect(await charge('booking-1'), isA<Success<MomoReceipt>>());
  });
}
