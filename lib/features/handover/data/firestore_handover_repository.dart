import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veloce/core/constants/firestore_fields.dart';
import 'package:veloce/core/constants/firestore_paths.dart';
import 'package:veloce/core/data/services/failure_mapper.dart';
import 'package:veloce/core/domain/entities/checklist_entry.dart';
import 'package:veloce/core/domain/entities/checklist_media.dart';
import 'package:veloce/core/domain/enums/checklist_kind.dart';
import 'package:veloce/core/domain/enums/checklist_side.dart';
import 'package:veloce/core/domain/services/atomic_write.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';

import '../domain/repositories/handover_repository.dart';

/// Saves handover checklist data to Firestore.
/// Pickup and return confirmation will be implemented separately.
abstract class FirestoreHandoverRepository implements HandoverRepository {
  const FirestoreHandoverRepository({
    required this._writes,
    required this._session,
  });

  static const Duration _timeout = Duration(seconds: 20);

  final AtomicWriteFactory _writes;
  final AuthSession _session;

  @override
  Future<Result<void>> saveChecklist({
    required String bookingId,
    required ChecklistKind kind,
    required ChecklistSide side,
    required List<ChecklistEntry> entries,
    required List<ChecklistMedia> media,
  }) async {
    final uid = _session.currentUserId;

    if (uid == null) {
      return const Result.failure(
        PermissionFailure('Sign in to save the checklist.'),
      );
    }

    if (bookingId.trim().isEmpty) {
      return const Result.failure(ValidationFailure('Booking ID is required.'));
    }

    // Check that every entry belongs to this checklist.
    for (final entry in entries) {
      if (entry.bookingId != bookingId ||
          entry.kind != kind ||
          entry.side != side) {
        return const Result.failure(
          ValidationFailure('Checklist entry does not match the booking.'),
        );
      }
    }

    // Check that every media item belongs to this checklist.
    for (final item in media) {
      if (item.bookingId != bookingId ||
          item.kind != kind ||
          item.side != side) {
        return const Result.failure(
          ValidationFailure('Checklist media does not match the booking.'),
        );
      }
    }

    try {
      final write = _writes.begin();
      final bookingPath = FirestorePaths.booking(bookingId);

      // Save checklist entries.
      for (final entry in entries) {
        final path =
            '$bookingPath/${FirestorePaths.checklistEntries}/${entry.id}';

        write.set(path, {
          FirestoreFields.id: entry.id,
          FirestoreFields.bookingId: entry.bookingId,
          FirestoreFields.kind: entry.kind.key,
          FirestoreFields.side: entry.side.key,
          FirestoreFields.item: entry.item,
          FirestoreFields.ticked: entry.ticked,
          FirestoreFields.at: Timestamp.fromDate(entry.at),
        });
      }

      // Save checklist photos and videos.
      for (final item in media) {
        final path = '$bookingPath/${FirestorePaths.checklistMedia}/${item.id}';

        write.set(path, {
          FirestoreFields.id: item.id,
          FirestoreFields.bookingId: item.bookingId,
          FirestoreFields.kind: item.kind.key,
          FirestoreFields.side: item.side.key,
          FirestoreFields.mediaType: item.mediaType.key,
          FirestoreFields.url: item.url,
          FirestoreFields.at: Timestamp.fromDate(item.at),
        });
      }

      await write.commit().timeout(_timeout);

      return const Result.success(null);
    } on Object catch (error, stackTrace) {
      return Result.failure(mapToFailure(error, stackTrace));
    }
  }
}
