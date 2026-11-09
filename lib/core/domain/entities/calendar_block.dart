import 'package:equatable/equatable.dart';

/// Public copy of a booking's dates so search can hide blocked days. Doc id is the booking id.
class CalendarBlock extends Equatable {
  const CalendarBlock({
    required this.bookingId,
    required this.vehicleId,
    required this.startDate,
    required this.endDate,
  });

  final String bookingId;
  final String vehicleId;
  final DateTime startDate;
  final DateTime endDate;

  CalendarBlock copyWith({
    String? bookingId,
    String? vehicleId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return CalendarBlock(
      bookingId: bookingId ?? this.bookingId,
      vehicleId: vehicleId ?? this.vehicleId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  @override
  List<Object?> get props => [bookingId, vehicleId, startDate, endDate];
}
