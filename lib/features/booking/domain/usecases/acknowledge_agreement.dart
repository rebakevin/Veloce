import 'package:veloce/core/error/result.dart';

import '../repositories/booking_repository.dart';

/// Records that the renter accepted the rental agreement before pickup.
class AcknowledgeAgreement {
  const AcknowledgeAgreement(this._repository);

  final BookingRepository _repository;

  Future<Result<void>> call(String bookingId) =>
      _repository.acknowledgeAgreement(bookingId);
}
