import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/features/booking/domain/entities/booking_view.dart';
import 'package:veloce/features/booking/domain/repositories/booking_repository.dart';

import '../../../support/builders.dart';

BookingView bookingView({
  BookingStatus status = BookingStatus.pending,
  BookingStatus? effectiveStatus,
  String id = 'booking-1',
  DateTime? start,
  DateTime? end,
  DateTime? expiresAt,
  DateTime? payDeadline,
}) {
  final booking = aBooking(
    status: status,
    id: id,
    expiresAt: expiresAt,
    payDeadline: payDeadline,
  ).copyWith(startDate: start, endDate: end);
  return BookingView(
    booking: booking,
    effectiveStatus: effectiveStatus ?? status,
    vehicle: aVehicle(),
    renter: aUser(),
    owner: aUser(role: UserRole.owner).copyWith(id: 'owner-1', name: 'Owner'),
  );
}

class MockBookingRepository extends Mock implements BookingRepository {}
