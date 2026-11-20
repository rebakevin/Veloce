import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/features/booking/domain/entities/booking_view.dart';
import 'package:veloce/features/booking/domain/repositories/booking_repository.dart';
import 'package:veloce/features/booking/domain/usecases/acknowledge_agreement.dart';
import 'package:veloce/features/booking/domain/usecases/approve_booking.dart';
import 'package:veloce/features/booking/domain/usecases/cancel_booking.dart';
import 'package:veloce/features/booking/domain/usecases/decline_booking.dart';
import 'package:veloce/features/booking/domain/usecases/expire_bookings.dart';
import 'package:veloce/features/booking/domain/usecases/pay_booking.dart';

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

class MockAuthSession extends Mock implements AuthSession {}

class MockCancelBooking extends Mock implements CancelBooking {}

class MockExpireBookings extends Mock implements ExpireBookings {}

class MockApproveBooking extends Mock implements ApproveBooking {}

class MockDeclineBooking extends Mock implements DeclineBooking {}

class MockPayBooking extends Mock implements PayBooking {}

class MockAcknowledgeAgreement extends Mock implements AcknowledgeAgreement {}
