import 'package:equatable/equatable.dart';

import '../enums/fuel_type.dart';
import '../enums/transmission.dart';
import '../enums/vehicle_status.dart';
import '../enums/vehicle_type.dart';
import 'long_rate.dart';

/// A car listed by an owner. Availability is the embedded [availableFrom]..[availableTo] window.
class Vehicle extends Equatable {
  const Vehicle({
    required this.id,
    required this.ownerId,
    required this.plate,
    required this.make,
    required this.model,
    required this.year,
    required this.type,
    required this.transmission,
    required this.fuel,
    required this.seats,
    required this.features,
    required this.description,
    required this.dailyPrice,
    required this.longRates,
    required this.cautionFee,
    required this.neighbourhood,
    required this.fuelRule,
    required this.smoking,
    required this.extras,
    required this.rulesFileUrl,
    required this.videoUrl,
    required this.status,
    required this.availableFrom,
    required this.availableTo,
    required this.docsValidUntil,
    required this.ratingAvg,
    required this.ratingCount,
    required this.createdAt,
  });

  final String id;
  final String ownerId;
  final String plate;
  final String make;
  final String model;
  final int year;
  final VehicleType type;
  final Transmission transmission;
  final FuelType fuel;
  final int seats;
  final List<String> features;
  final String description;
  final int dailyPrice;
  final List<LongRate> longRates;
  final int cautionFee;
  final String neighbourhood;
  final String fuelRule;
  final String smoking;
  final List<String> extras;
  final String? rulesFileUrl;
  final String? videoUrl;
  final VehicleStatus status;
  final DateTime? availableFrom;
  final DateTime? availableTo;
  final DateTime? docsValidUntil;
  final double ratingAvg;
  final int ratingCount;
  final DateTime createdAt;

  Vehicle copyWith({
    String? id,
    String? ownerId,
    String? plate,
    String? make,
    String? model,
    int? year,
    VehicleType? type,
    Transmission? transmission,
    FuelType? fuel,
    int? seats,
    List<String>? features,
    String? description,
    int? dailyPrice,
    List<LongRate>? longRates,
    int? cautionFee,
    String? neighbourhood,
    String? fuelRule,
    String? smoking,
    List<String>? extras,
    String? rulesFileUrl,
    String? videoUrl,
    VehicleStatus? status,
    DateTime? availableFrom,
    DateTime? availableTo,
    DateTime? docsValidUntil,
    double? ratingAvg,
    int? ratingCount,
    DateTime? createdAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      plate: plate ?? this.plate,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      type: type ?? this.type,
      transmission: transmission ?? this.transmission,
      fuel: fuel ?? this.fuel,
      seats: seats ?? this.seats,
      features: features ?? this.features,
      description: description ?? this.description,
      dailyPrice: dailyPrice ?? this.dailyPrice,
      longRates: longRates ?? this.longRates,
      cautionFee: cautionFee ?? this.cautionFee,
      neighbourhood: neighbourhood ?? this.neighbourhood,
      fuelRule: fuelRule ?? this.fuelRule,
      smoking: smoking ?? this.smoking,
      extras: extras ?? this.extras,
      rulesFileUrl: rulesFileUrl ?? this.rulesFileUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      status: status ?? this.status,
      availableFrom: availableFrom ?? this.availableFrom,
      availableTo: availableTo ?? this.availableTo,
      docsValidUntil: docsValidUntil ?? this.docsValidUntil,
      ratingAvg: ratingAvg ?? this.ratingAvg,
      ratingCount: ratingCount ?? this.ratingCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    ownerId,
    plate,
    make,
    model,
    year,
    type,
    transmission,
    fuel,
    seats,
    features,
    description,
    dailyPrice,
    longRates,
    cautionFee,
    neighbourhood,
    fuelRule,
    smoking,
    extras,
    rulesFileUrl,
    videoUrl,
    status,
    availableFrom,
    availableTo,
    docsValidUntil,
    ratingAvg,
    ratingCount,
    createdAt,
  ];
}
