import '../../constants/firestore_fields.dart';
import '../../domain/entities/payout_method.dart';
import 'wire.dart';

/// Maps [PayoutMethod] to and from the Firestore wire map.
abstract final class PayoutMethodModel {
  static PayoutMethod fromMap(String docId, Map<String, dynamic> map) {
    final wire = WireReader('PayoutMethod', map);
    return PayoutMethod(
      userId: docId,
      momoNumber: wire.string(FirestoreFields.momoNumber),
    );
  }

  static Map<String, dynamic> toMap(PayoutMethod entity) => {
    FirestoreFields.momoNumber: entity.momoNumber,
  };
}
