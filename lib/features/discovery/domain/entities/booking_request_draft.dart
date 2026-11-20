import 'package:equatable/equatable.dart';

import 'package:veloce/core/domain/entities/vehicle.dart';
import 'package:veloce/core/domain/services/price_quote.dart';

/// The car, dates and locked quote a renter is about to request.
class BookingRequestDraft extends Equatable {
  const BookingRequestDraft({
    required this.vehicle,
    required this.start,
    required this.end,
    required this.quote,
  });

  final Vehicle vehicle;
  final DateTime start;
  final DateTime end;
  final PriceQuote quote;

  @override
  List<Object?> get props => [vehicle, start, end, quote];
}
