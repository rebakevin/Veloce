import 'package:veloce/core/domain/entities/calendar_block.dart';
import 'package:veloce/core/domain/entities/vehicle.dart';

/// Pure date rules shared by search, the detail calendar and the request use
/// case. Dates are compared by calendar day; the return day is not charged.
class AvailabilityRules {
  const AvailabilityRules();

  DateTime day(DateTime value) => DateTime(value.year, value.month, value.day);

  bool isPast(DateTime start, DateTime now) => day(start).isBefore(day(now));

  bool hasValidDocs(Vehicle vehicle, DateTime now) {
    final validUntil = vehicle.docsValidUntil;
    if (validUntil == null) return false;
    return !day(validUntil).isBefore(day(now));
  }

  bool isWithinWindow(Vehicle vehicle, DateTime start, DateTime end) {
    final from = vehicle.availableFrom;
    final to = vehicle.availableTo;
    if (from == null || to == null) return false;
    final requestedStart = day(start);
    final requestedEnd = day(end);
    return !requestedStart.isBefore(day(from)) &&
        !requestedEnd.isAfter(day(to)) &&
        !requestedEnd.isBefore(requestedStart);
  }

  /// A block overlaps when `block.start < requested.end` and
  /// `block.end > requested.start`; a block ending on the pickup day is free.
  bool blockOverlaps(
    CalendarBlock block,
    DateTime requestedStart,
    DateTime requestedEnd,
  ) {
    final start = day(requestedStart);
    final end = day(requestedEnd);
    return day(block.startDate).isBefore(end) &&
        day(block.endDate).isAfter(start);
  }

  bool isFree(
    Iterable<CalendarBlock> blocks,
    DateTime requestedStart,
    DateTime requestedEnd,
  ) => !blocks.any(
    (block) => blockOverlaps(block, requestedStart, requestedEnd),
  );

  bool isAvailable({
    required Vehicle vehicle,
    required Iterable<CalendarBlock> blocks,
    required DateTime start,
    required DateTime end,
    required DateTime now,
  }) {
    return !isPast(start, now) &&
        isWithinWindow(vehicle, start, end) &&
        isFree(blocks, start, end);
  }
}
