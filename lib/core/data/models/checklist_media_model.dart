import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/firestore_fields.dart';
import '../../domain/entities/checklist_media.dart';
import '../../domain/enums/checklist_kind.dart';
import '../../domain/enums/checklist_side.dart';
import '../../domain/enums/media_type.dart';
import 'wire.dart';

/// Maps [ChecklistMedia] to and from the Firestore wire map.
abstract final class ChecklistMediaModel {
  static ChecklistMedia fromMap(String docId, Map<String, dynamic> map) {
    final wire = WireReader('ChecklistMedia', map);
    return ChecklistMedia(
      id: docId,
      bookingId: wire.string(FirestoreFields.bookingId),
      kind: wire.enumValue(FirestoreFields.kind, ChecklistKind.fromKey),
      side: wire.enumValue(FirestoreFields.side, ChecklistSide.fromKey),
      mediaType: wire.enumValue(FirestoreFields.mediaType, MediaType.fromKey),
      url: wire.string(FirestoreFields.url),
      at: wire.dateTime(FirestoreFields.at),
    );
  }

  static Map<String, dynamic> toMap(ChecklistMedia entity) => {
    FirestoreFields.bookingId: entity.bookingId,
    FirestoreFields.kind: entity.kind.key,
    FirestoreFields.side: entity.side.key,
    FirestoreFields.mediaType: entity.mediaType.key,
    FirestoreFields.url: entity.url,
    FirestoreFields.at: Timestamp.fromDate(entity.at),
  };
}
