import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/firestore_paths.dart';
import '../../domain/entities/booking.dart';
import '../models/booking_model.dart';
import 'cached_document_lookup.dart';

/// Cached read-by-id and stream of [Booking] for cross-feature reads.
class BookingLookup extends CachedDocumentLookup<Booking> {
  BookingLookup(FirebaseFirestore firestore)
    : super(
        firestore: firestore,
        collection: FirestorePaths.bookings,
        fromMap: BookingModel.fromMap,
      );
}
