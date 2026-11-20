import 'package:equatable/equatable.dart';
import 'package:veloce/core/domain/entities/vehicle.dart';

/// Represents a single car's earnings and losses with its share of total earnings.
class CarFinanceShare extends Equatable {
  const CarFinanceShare({
    required this.vehicle,
    required this.earned,
    required this.losses,
    required this.share,
  });

  final Vehicle vehicle;
  final int earned;
  final int losses;
  final double share; // 0.0 to 1.0

  @override
  List<Object?> get props => [vehicle, earned, losses, share];
}
