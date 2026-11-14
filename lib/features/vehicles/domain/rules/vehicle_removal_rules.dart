import '../../../../core/domain/entities/booking.dart';
import '../../../../core/domain/services/booking_state_machine.dart';

abstract final class VehicleRemovalRules {
  static String? check(
    Iterable<Booking> bookings, {
    required DateTime now,
    BookingStateMachine machine = const BookingStateMachine(),
  }) {
    final hasOpenBooking = bookings.any(
      (booking) =>
          !machine.isTerminal(machine.effectiveStatus(booking, now: now)),
    );
    if (hasOpenBooking) {
      return 'This car has open bookings. Finish or cancel them before '
          'removing it.';
    }
    return null;
  }
}
