import '../../error/result.dart';

/// Proof of a (simulated) MoMo payment.
class MomoReceipt {
  const MomoReceipt({required this.reference});

  final String reference;
}

/// Mobile-money payments. Swap the simulation for the real MTN API later.
abstract interface class MomoGateway {
  Future<Result<MomoReceipt>> charge({
    required String momoNumber,
    required int amount,
    required String bookingReference,
  });
}
