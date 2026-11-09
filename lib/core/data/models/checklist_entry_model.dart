import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/firestore_fields.dart';
import '../../domain/entities/checklist_entry.dart';
import '../../domain/enums/checklist_kind.dart';
import '../../domain/enums/checklist_side.dart';
import 'wire.dart';

/// Maps [ChecklistEntry] to and from the Firestore wire map.
abstract final class ChecklistEntryModel {
  static ChecklistEntry fromMap(String docId, Map<String, dynamic> map) {
    final wire = WireReader('ChecklistEntry', map);
    return ChecklistEntry(
      id: docId,
      bookingId: wire.string(FirestoreFields.bookingId),
      kind: wire.enumValue(FirestoreFields.kind, ChecklistKind.fromKey),
      side: wire.enumValue(FirestoreFields.side, ChecklistSide.fromKey),
      item: wire.string(FirestoreFields.item),
      ticked: wire.boolean(FirestoreFields.ticked),
      at: wire.dateTime(FirestoreFields.at),
    );
  }

  static Map<String, dynamic> toMap(ChecklistEntry entity) => {
    FirestoreFields.bookingId: entity.bookingId,
    FirestoreFields.kind: entity.kind.key,
    FirestoreFields.side: entity.side.key,
    FirestoreFields.item: entity.item,
    FirestoreFields.ticked: entity.ticked,
    FirestoreFields.at: Timestamp.fromDate(entity.at),
  };
}
