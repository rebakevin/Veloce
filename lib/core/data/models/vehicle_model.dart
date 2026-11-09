import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/firestore_fields.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/enums/fuel_type.dart';
import '../../domain/enums/transmission.dart';
import '../../domain/enums/vehicle_status.dart';
import '../../domain/enums/vehicle_type.dart';
import 'long_rate_model.dart';
import 'wire.dart';

/// Maps [Vehicle] to and from the Firestore wire map.
abstract final class VehicleModel {
  static Vehicle fromMap(String docId, Map<String, dynamic> map) {
    final wire = WireReader('Vehicle', map);
    return Vehicle(
      id: docId,
      ownerId: wire.string(FirestoreFields.ownerId),
      plate: wire.string(FirestoreFields.plate),
      make: wire.string(FirestoreFields.make),
      model: wire.string(FirestoreFields.model),
      year: wire.integer(FirestoreFields.year),
      type: wire.enumValue(FirestoreFields.type, VehicleType.fromKey),
      transmission: wire.enumValue(
        FirestoreFields.transmission,
        Transmission.fromKey,
      ),
      fuel: wire.enumValue(FirestoreFields.fuel, FuelType.fromKey),
      seats: wire.integer(FirestoreFields.seats),
      features: wire.stringList(FirestoreFields.features),
      description: wire.string(FirestoreFields.description),
      dailyPrice: wire.integer(FirestoreFields.dailyPrice),
      longRates: wire
          .mapList(FirestoreFields.longRates)
          .map(LongRateModel.fromMap)
          .toList(),
      cautionFee: wire.integer(FirestoreFields.cautionFee),
      neighbourhood: wire.string(FirestoreFields.neighbourhood),
      fuelRule: wire.string(FirestoreFields.fuelRule),
      smoking: wire.string(FirestoreFields.smoking),
      extras: wire.stringList(FirestoreFields.extras),
      rulesFileUrl: wire.optionalString(FirestoreFields.rulesFileUrl),
      videoUrl: wire.optionalString(FirestoreFields.videoUrl),
      status: wire.enumValue(FirestoreFields.status, VehicleStatus.fromKey),
      availableFrom: wire.optionalDateTime(FirestoreFields.availableFrom),
      availableTo: wire.optionalDateTime(FirestoreFields.availableTo),
      docsValidUntil: wire.optionalDateTime(FirestoreFields.docsValidUntil),
      ratingAvg: wire.decimal(FirestoreFields.ratingAvg),
      ratingCount: wire.integer(FirestoreFields.ratingCount),
      createdAt: wire.dateTime(FirestoreFields.createdAt),
    );
  }

  static Map<String, dynamic> toMap(Vehicle entity) => {
    FirestoreFields.ownerId: entity.ownerId,
    FirestoreFields.plate: entity.plate,
    FirestoreFields.make: entity.make,
    FirestoreFields.model: entity.model,
    FirestoreFields.year: entity.year,
    FirestoreFields.type: entity.type.key,
    FirestoreFields.transmission: entity.transmission.key,
    FirestoreFields.fuel: entity.fuel.key,
    FirestoreFields.seats: entity.seats,
    FirestoreFields.features: entity.features,
    FirestoreFields.description: entity.description,
    FirestoreFields.dailyPrice: entity.dailyPrice,
    FirestoreFields.longRates: entity.longRates
        .map(LongRateModel.toMap)
        .toList(),
    FirestoreFields.cautionFee: entity.cautionFee,
    FirestoreFields.neighbourhood: entity.neighbourhood,
    FirestoreFields.fuelRule: entity.fuelRule,
    FirestoreFields.smoking: entity.smoking,
    FirestoreFields.extras: entity.extras,
    FirestoreFields.rulesFileUrl: entity.rulesFileUrl,
    FirestoreFields.videoUrl: entity.videoUrl,
    FirestoreFields.status: entity.status.key,
    FirestoreFields.availableFrom: timestampOrNull(entity.availableFrom),
    FirestoreFields.availableTo: timestampOrNull(entity.availableTo),
    FirestoreFields.docsValidUntil: timestampOrNull(entity.docsValidUntil),
    FirestoreFields.ratingAvg: entity.ratingAvg,
    FirestoreFields.ratingCount: entity.ratingCount,
    FirestoreFields.createdAt: Timestamp.fromDate(entity.createdAt),
  };
}
