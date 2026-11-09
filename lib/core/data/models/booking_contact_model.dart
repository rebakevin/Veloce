import '../../constants/firestore_fields.dart';
import '../../domain/entities/booking_contact.dart';
import '../../domain/enums/checklist_side.dart';
import 'wire.dart';

/// Maps [BookingContact] to and from the Firestore wire map.
abstract final class BookingContactModel {
  static BookingContact fromMap(String docId, Map<String, dynamic> map) {
    final wire = WireReader('BookingContact', map);
    return BookingContact(
      side: ChecklistSide.fromKey(docId),
      bookingId: wire.string(FirestoreFields.bookingId),
      phone: wire.string(FirestoreFields.phone),
      email: wire.string(FirestoreFields.email),
      meetingPoint: wire.optionalString(FirestoreFields.meetingPoint),
    );
  }

  static Map<String, dynamic> toMap(BookingContact entity) => {
    FirestoreFields.bookingId: entity.bookingId,
    FirestoreFields.phone: entity.phone,
    FirestoreFields.email: entity.email,
    FirestoreFields.meetingPoint: entity.meetingPoint,
  };
}
