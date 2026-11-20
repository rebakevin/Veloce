import 'package:equatable/equatable.dart';
import 'package:veloce/core/domain/entities/document_photo.dart';
import 'package:veloce/core/domain/entities/long_rate.dart';
import 'package:veloce/core/domain/entities/vehicle_photo.dart';
import 'package:veloce/core/domain/enums/document_kind.dart';
import 'package:veloce/core/domain/enums/fuel_type.dart';
import 'package:veloce/core/domain/enums/transmission.dart';
import 'package:veloce/core/domain/enums/vehicle_type.dart';

class DraftDocument extends Equatable {
  const DraftDocument({
    this.photo,
    this.number = '',
    this.plate = '',
    this.expiry,
    this.verified = false,
  });

  final DocumentPhoto? photo;
  final String number;
  final String plate;
  final DateTime? expiry;
  final bool verified;

  DraftDocument copyWith({
    DocumentPhoto? photo,
    bool clearPhoto = false,
    String? number,
    String? plate,
    DateTime? expiry,
    bool? verified,
  }) {
    return DraftDocument(
      photo: clearPhoto ? null : photo ?? this.photo,
      number: number ?? this.number,
      plate: plate ?? this.plate,
      expiry: expiry ?? this.expiry,
      verified: verified ?? this.verified,
    );
  }

  @override
  List<Object?> get props => [photo, number, plate, expiry, verified];
}

class WizardDraft extends Equatable {
  const WizardDraft({
    this.vehicleId,
    this.keptPhotos = const [],
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
    this.documents = const {},
  });

  /// Set when an existing car is being edited; null when listing a new one.
  final String? vehicleId;

  /// Photos the car already has, shown before the newly picked [photos].
  final List<VehiclePhoto> keptPhotos;
  final List<DocumentPhoto> photos;

  /// Index of the main photo across [keptPhotos] followed by [photos].
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
  final Map<DocumentKind, DraftDocument> documents;

  bool get isEditing => vehicleId != null;

  int get photoCount => keptPhotos.length + photos.length;

  WizardDraft copyWith({
    String? vehicleId,
    List<VehiclePhoto>? keptPhotos,
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
    Map<DocumentKind, DraftDocument>? documents,
  }) {
    return WizardDraft(
      vehicleId: vehicleId ?? this.vehicleId,
      keptPhotos: keptPhotos ?? this.keptPhotos,
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
      documents: documents ?? this.documents,
    );
  }

  @override
  List<Object?> get props => [
    vehicleId,
    keptPhotos,
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
    documents,
  ];
}
