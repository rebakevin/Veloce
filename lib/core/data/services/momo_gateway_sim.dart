import '../../domain/services/clock.dart';
import '../../domain/services/momo_gateway.dart';
import '../../error/app_failure.dart';
import '../../error/result.dart';

/// Simulated MoMo. Flip [shouldSucceed] to demo the payment-failure retry.
class MomoGatewaySim implements MomoGateway {
  MomoGatewaySim(this._clock);

  final Clock _clock;

  bool shouldSucceed = true;

  @override
  Future<Result<MomoReceipt>> charge({
    required String momoNumber,
    required int amount,
    required String bookingReference,
  }) async {
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!shouldSucceed) {
      return const Result.failure(
        ConflictFailure('The payment was not approved. Please try again.'),
      );
    }
    final reference = 'MOMO-${_clock.now().millisecondsSinceEpoch}';
    return Result.success(MomoReceipt(reference: reference));
  }
}
