import 'package:equatable/equatable.dart';
import 'package:veloce/core/domain/entities/vehicle.dart';
import 'package:veloce/core/domain/enums/transmission.dart';
import 'package:veloce/core/domain/enums/vehicle_type.dart';

/// Filters applied after the area and date query. Every field is optional;
/// [activeCount] counts the fields the renter has changed from "Any".
class VehicleFilters extends Equatable {
  const VehicleFilters({
    this.minPrice,
    this.maxPrice,
    this.type,
    this.transmission,
    this.minSeats,
  });

  static const VehicleFilters none = VehicleFilters();

  final int? minPrice;
  final int? maxPrice;
  final VehicleType? type;
  final Transmission? transmission;
  final int? minSeats;

  /// False when both prices are set and the minimum is above the maximum.
  bool get hasValidPriceRange {
    final min = minPrice;
    final max = maxPrice;
    return min == null || max == null || min <= max;
  }

  int get activeCount => [
    minPrice,
    maxPrice,
    type,
    transmission,
    minSeats,
  ].where((value) => value != null).length;

  VehicleFilters copyWith({
    int? minPrice,
    int? maxPrice,
    VehicleType? type,
    Transmission? transmission,
    int? minSeats,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
    bool clearType = false,
    bool clearTransmission = false,
    bool clearMinSeats = false,
  }) {
    return VehicleFilters(
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      type: clearType ? null : (type ?? this.type),
      transmission: clearTransmission
          ? null
          : (transmission ?? this.transmission),
      minSeats: clearMinSeats ? null : (minSeats ?? this.minSeats),
    );
  }

  /// Price filters compare the base daily price, not a long-rental tier rate.
  bool matches(Vehicle vehicle) {
    final min = minPrice;
    final max = maxPrice;
    final wantedType = type;
    final wantedTransmission = transmission;
    final seats = minSeats;
    if (min != null && vehicle.dailyPrice < min) return false;
    if (max != null && vehicle.dailyPrice > max) return false;
    if (wantedType != null && vehicle.type != wantedType) return false;
    if (wantedTransmission != null &&
        vehicle.transmission != wantedTransmission) {
      return false;
    }
    if (seats != null && vehicle.seats < seats) return false;
    return true;
  }

  @override
  List<Object?> get props => [minPrice, maxPrice, type, transmission, minSeats];
}
