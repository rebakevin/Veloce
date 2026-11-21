import '../../domain/services/momo_gateway.dart';
import '../../error/app_failure.dart';
import '../../error/result.dart';

/// Simulated MoMo. Flip [shouldSucceed] to demo the payment-failure retry.
class MomoGatewaySim implements MomoGateway {
  bool shouldSucceed = true;

  /// Receipts by idempotency key. Kept in memory: the simulation moves no
  /// money, and the reference below is derived from the key, so a retry after
  /// a restart still yields the same reference.
  final Map<String, MomoReceipt> _receipts = {};

  @override
  Future<Result<MomoReceipt>> charge({
    required String momoNumber,
    required int amount,
    required String bookingReference,
    required String idempotencyKey,
  }) async {
    final earlier = _receipts[idempotencyKey];
    if (earlier != null) return Result.success(earlier);
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!shouldSucceed) {
      return const Result.failure(
        ConflictFailure('The payment was not approved. Please try again.'),
      );
    }
    final receipt = MomoReceipt(reference: 'MOMO-$bookingReference');
    _receipts[idempotencyKey] = receipt;
    return Result.success(receipt);
  }
}
