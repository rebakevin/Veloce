import 'package:equatable/equatable.dart';
import 'package:veloce/core/domain/entities/document_photo.dart';
import 'package:veloce/core/domain/entities/long_rate.dart';
import 'package:veloce/core/domain/enums/fuel_type.dart';
import 'package:veloce/core/domain/enums/transmission.dart';
import 'package:veloce/core/domain/enums/vehicle_type.dart';

class WizardDraft extends Equatable {
  const WizardDraft({
    this.photos = const [],
    this.primaryIndex = 0,
    this.video,
    this.plate = '',
    this.make = '',
    this.model = '',
    this.year,
    this.type,
    this.neighbourhood = '',
    this.description = '',
    this.transmission,
    this.fuel,
    this.seats,
    this.features = const [],
    this.dailyPrice,
    this.longRates = const [],
    this.cautionFee,
    this.fuelRule = '',
    this.smoking = '',
    this.extras = const [],
    this.rulesPdf,
  });

  final List<DocumentPhoto> photos;
  final int primaryIndex;
  final DocumentPhoto? video;
  final String plate;
  final String make;
  final String model;
  final int? year;
  final VehicleType? type;
  final String neighbourhood;
  final String description;
  final Transmission? transmission;
  final FuelType? fuel;
  final int? seats;
  final List<String> features;
  final int? dailyPrice;
  final List<LongRate> longRates;
  final int? cautionFee;
  final String fuelRule;
  final String smoking;
  final List<String> extras;
  final DocumentPhoto? rulesPdf;

  WizardDraft copyWith({
    List<DocumentPhoto>? photos,
    int? primaryIndex,
    DocumentPhoto? video,
    bool clearVideo = false,
    String? plate,
    String? make,
    String? model,
    int? year,
    VehicleType? type,
    String? neighbourhood,
    String? description,
    Transmission? transmission,
    FuelType? fuel,
    int? seats,
    List<String>? features,
    int? dailyPrice,
    List<LongRate>? longRates,
    int? cautionFee,
    String? fuelRule,
    String? smoking,
    List<String>? extras,
    DocumentPhoto? rulesPdf,
    bool clearRulesPdf = false,
  }) {
    return WizardDraft(
      photos: photos ?? this.photos,
      primaryIndex: primaryIndex ?? this.primaryIndex,
      video: clearVideo ? null : video ?? this.video,
      plate: plate ?? this.plate,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      type: type ?? this.type,
      neighbourhood: neighbourhood ?? this.neighbourhood,
      description: description ?? this.description,
      transmission: transmission ?? this.transmission,
      fuel: fuel ?? this.fuel,
      seats: seats ?? this.seats,
      features: features ?? this.features,
      dailyPrice: dailyPrice ?? this.dailyPrice,
      longRates: longRates ?? this.longRates,
      cautionFee: cautionFee ?? this.cautionFee,
      fuelRule: fuelRule ?? this.fuelRule,
      smoking: smoking ?? this.smoking,
      extras: extras ?? this.extras,
      rulesPdf: clearRulesPdf ? null : rulesPdf ?? this.rulesPdf,
    );
  }

  @override
  List<Object?> get props => [
    photos,
    primaryIndex,
    video,
    plate,
    make,
    model,
    year,
    type,
    neighbourhood,
    description,
    transmission,
    fuel,
    seats,
    features,
    dailyPrice,
    longRates,
    cautionFee,
    fuelRule,
    smoking,
    extras,
    rulesPdf,
  ];
}
