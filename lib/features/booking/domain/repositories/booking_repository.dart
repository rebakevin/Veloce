import 'package:veloce/core/domain/entities/booking_contact.dart';
import 'package:veloce/core/domain/services/momo_gateway.dart';
import 'package:veloce/core/error/result.dart';

import '../entities/booking_view.dart';

/// Reads and transitions for the signed-in renter or owner. All multi-document
/// changes happen in one atomic write inside the data layer.
abstract interface class BookingRepository {
  Stream<Result<List<BookingView>>> watchMyBookings();

  Stream<Result<BookingView>> watchBooking(String bookingId);

  Future<Result<BookingView>> getBooking(String bookingId);

  /// The other party's contact details, or `null` while the booking is not
  /// paid. Never reads a locked contact document.
  Future<Result<BookingContact?>> getCounterpartyContact(String bookingId);

  Future<Result<void>> approve(String bookingId);

  Future<Result<void>> decline(String bookingId, {required String reason});

  Future<Result<void>> cancel(String bookingId, {String? reason});

  Future<Result<MomoReceipt>> pay(
    String bookingId, {
    required String momoNumber,
  });

  Future<Result<void>> acknowledgeAgreement(String bookingId);

  /// Persists every expired open booking of the signed-in user and returns how
  /// many were written.
  Future<Result<int>> expireDueBookings();
}
