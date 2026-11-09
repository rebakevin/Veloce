import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/firestore_fields.dart';
import '../../domain/entities/review.dart';
import '../../domain/enums/subject_type.dart';
import 'wire.dart';

/// Maps [Review] to and from the Firestore wire map.
abstract final class ReviewModel {
  static Review fromMap(String docId, Map<String, dynamic> map) {
    final wire = WireReader('Review', map);
    return Review(
      id: docId,
      bookingId: wire.string(FirestoreFields.bookingId),
      authorId: wire.string(FirestoreFields.authorId),
      subjectType: wire.enumValue(
        FirestoreFields.subjectType,
        SubjectType.fromKey,
      ),
      subjectId: wire.string(FirestoreFields.subjectId),
      stars: wire.integer(FirestoreFields.stars),
      comment: wire.string(FirestoreFields.comment),
      createdAt: wire.dateTime(FirestoreFields.createdAt),
      editedAt: wire.optionalDateTime(FirestoreFields.editedAt),
    );
  }

  static Map<String, dynamic> toMap(Review entity) => {
    FirestoreFields.bookingId: entity.bookingId,
    FirestoreFields.authorId: entity.authorId,
    FirestoreFields.subjectType: entity.subjectType.key,
    FirestoreFields.subjectId: entity.subjectId,
    FirestoreFields.stars: entity.stars,
    FirestoreFields.comment: entity.comment,
    FirestoreFields.createdAt: Timestamp.fromDate(entity.createdAt),
    FirestoreFields.editedAt: timestampOrNull(entity.editedAt),
  };
}
