import 'package:equatable/equatable.dart';
import 'package:veloce/core/domain/entities/vehicle.dart';

import 'day_range.dart';

/// A car with the days its open bookings lock.
class AvailabilityOverview extends Equatable {
  const AvailabilityOverview({required this.vehicle, required this.bookedDays});

  final Vehicle vehicle;
  final List<DayRange> bookedDays;

  @override
  List<Object?> get props => [vehicle, bookedDays];
}
