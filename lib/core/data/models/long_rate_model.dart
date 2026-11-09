import '../../constants/firestore_fields.dart';
import '../../domain/entities/long_rate.dart';
import 'wire.dart';

/// Maps [LongRate] to and from the Firestore wire map.
abstract final class LongRateModel {
  static LongRate fromMap(Map<String, dynamic> map) {
    final wire = WireReader('LongRate', map);
    return LongRate(
      fromDays: wire.integer(FirestoreFields.fromDays),
      pricePerDay: wire.integer(FirestoreFields.pricePerDay),
    );
  }

  static Map<String, dynamic> toMap(LongRate entity) => {
    FirestoreFields.fromDays: entity.fromDays,
    FirestoreFields.pricePerDay: entity.pricePerDay,
  };
}
