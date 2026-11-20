import '../../../../core/domain/entities/booking.dart';
import '../../../../core/domain/services/booking_state_machine.dart';
import '../entities/day_range.dart';

/// One availability range per car; days with an open booking stay inside it.
abstract final class AvailabilityRules {
  /// Days locked by bookings that are not finished, earliest first.
  static List<DayRange> bookedDays(
    Iterable<Booking> bookings, {
    required DateTime now,
    BookingStateMachine machine = const BookingStateMachine(),
  }) {
    final ranges = [
      for (final booking in bookings)
        if (!machine.isTerminal(machine.effectiveStatus(booking, now: now)))
          DayRange(booking.startDate, booking.endDate),
    ]..sort((a, b) => a.start.compareTo(b.start));
    return ranges;
  }

  /// Returns why `from`..`to` cannot be saved, or null when it can.
  static String? check({
    required DateTime? from,
    required DateTime? to,
    required Iterable<DayRange> bookedDays,
  }) {
    if ((from == null) != (to == null)) {
      return 'Choose both a start and an end date.';
    }
    if (from == null || to == null) {
      return bookedDays.isEmpty
          ? null
          : 'This car has booked days, so it cannot be left without dates.';
    }
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    if (start.isAfter(end)) return 'The start date must not be after the end.';
    for (final booked in bookedDays) {
      if (booked.start.isBefore(start) || booked.end.isAfter(end)) {
        return 'A booking from ${_day(booked.start)} to ${_day(booked.end)} '
            'is inside your dates. Keep that period available.';
      }
    }
    return null;
  }

  static String _day(DateTime day) =>
      '${day.day.toString().padLeft(2, '0')}/'
      '${day.month.toString().padLeft(2, '0')}/${day.year}';
}
