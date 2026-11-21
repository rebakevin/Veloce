import 'package:equatable/equatable.dart';
import 'package:veloce/core/domain/entities/document_photo.dart';
import 'package:veloce/core/domain/entities/long_rate.dart';
import 'package:veloce/core/domain/entities/vehicle_photo.dart';
import 'package:veloce/core/domain/enums/document_kind.dart';
import 'package:veloce/core/domain/enums/fuel_type.dart';
import 'package:veloce/core/domain/enums/transmission.dart';
import 'package:veloce/core/domain/enums/vehicle_type.dart';

import 'rules_pdf.dart';

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
    this.existingVideoUrl,
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
    this.existingRulesUrl,
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

  /// Video the car already has when editing; null once the owner removes it.
  final String? existingVideoUrl;
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
  final RulesPdf? rulesPdf;

  /// Rules PDF the car already has when editing; null once the owner removes it.
  final String? existingRulesUrl;
  final Map<DocumentKind, DraftDocument> documents;

  bool get isEditing => vehicleId != null;

  int get photoCount => keptPhotos.length + photos.length;

  /// Whether the photo at [index] (across kept then new photos) can move one
  /// place by [delta] (-1 earlier, 1 later). Photos stay inside their own
  /// group: kept photos before the newly picked ones.
  bool canMovePhoto(int index, int delta) {
    final kept = keptPhotos.length;
    final target = index + delta;
    if (index < 0 || index >= photoCount || target < 0) return false;
    if (target >= photoCount) return false;
    return (index < kept) == (target < kept);
  }

  /// The draft with the photo at [index] moved by [delta], keeping
  /// [primaryIndex] on the same photo. Unchanged when the move is not allowed.
  WizardDraft movePhoto(int index, int delta) {
    if (!canMovePhoto(index, delta)) return this;
    final target = index + delta;
    final kept = keptPhotos.length;
    final newKept = [...keptPhotos];
    final newPhotos = [...photos];
    if (index < kept) {
      newKept.insert(target, newKept.removeAt(index));
    } else {
      newPhotos.insert(target - kept, newPhotos.removeAt(index - kept));
    }
    final primary = primaryIndex == index
        ? target
        : primaryIndex == target
        ? index
        : primaryIndex;
    return copyWith(
      keptPhotos: newKept,
      photos: newPhotos,
      primaryIndex: primary,
    );
  }

  WizardDraft copyWith({
    String? vehicleId,
    List<VehiclePhoto>? keptPhotos,
    List<DocumentPhoto>? photos,
    int? primaryIndex,
    DocumentPhoto? video,
    bool clearVideo = false,
    String? existingVideoUrl,
    bool clearExistingVideo = false,
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
    RulesPdf? rulesPdf,
    bool clearRulesPdf = false,
    String? existingRulesUrl,
    bool clearExistingRules = false,
    Map<DocumentKind, DraftDocument>? documents,
  }) {
    return WizardDraft(
      vehicleId: vehicleId ?? this.vehicleId,
      keptPhotos: keptPhotos ?? this.keptPhotos,
      photos: photos ?? this.photos,
      primaryIndex: primaryIndex ?? this.primaryIndex,
      video: clearVideo ? null : video ?? this.video,
      existingVideoUrl: clearExistingVideo
          ? null
          : existingVideoUrl ?? this.existingVideoUrl,
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
      existingRulesUrl: clearExistingRules
          ? null
          : existingRulesUrl ?? this.existingRulesUrl,
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
    existingVideoUrl,
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
    existingRulesUrl,
    documents,
  ];
}
