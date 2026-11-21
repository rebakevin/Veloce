import '../../error/result.dart';

/// Proof of a (simulated) MoMo payment.
class MomoReceipt {
  const MomoReceipt({required this.reference});

  final String reference;
}

/// Mobile-money payments. Swap the simulation for the real MTN API later.
abstract interface class MomoGateway {
  /// Charges [amount] once per [idempotencyKey]. Calling again with the same
  /// key returns the original receipt and never debits a second time, so a
  /// caller that lost the response (or failed to record the payment) can
  /// retry safely. The real MTN API does this with its reference id.
  Future<Result<MomoReceipt>> charge({
    required String momoNumber,
    required int amount,
    required String bookingReference,
    required String idempotencyKey,
  });
}
