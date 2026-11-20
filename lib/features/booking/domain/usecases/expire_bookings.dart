import 'package:veloce/core/error/result.dart';

import '../repositories/booking_repository.dart';

/// Persists the expiries that [BookingRepository.watchMyBookings] already shows
/// through `effectiveStatus`.
class ExpireBookings {
  const ExpireBookings(this._repository);

  final BookingRepository _repository;

  Future<Result<int>> call() => _repository.expireDueBookings();
}
