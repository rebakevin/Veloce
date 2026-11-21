import 'package:veloce/core/error/result.dart';

import '../../../../core/domain/entities/booking.dart';
import '../../../../core/domain/entities/caution_claim.dart';
import '../../../../core/domain/entities/checklist_entry.dart';
import '../../../../core/domain/entities/checklist_media.dart';
import '../../../../core/domain/enums/booking_actor.dart';
import '../../../../core/domain/enums/checklist_kind.dart';
import '../../../../core/domain/enums/checklist_side.dart';
import '../../../../core/domain/enums/claim_response.dart';

/// A side's saved checklist for one step.
class SavedChecklist {
  const SavedChecklist({required this.entries, required this.media});

  final List<ChecklistEntry> entries;
  final List<ChecklistMedia> media;
}

abstract interface class HandoverRepository {
  /// The caution claim of a booking, or null while there is none.
  Stream<CautionClaim?> watchClaim(String bookingId);

  Future<Result<void>> saveChecklist({
    required String bookingId,
    required ChecklistKind kind,
    required ChecklistSide side,
    required List<ChecklistEntry> entries,
    required List<ChecklistMedia> media,
  });

  /// What this side already saved for the step (empty when nothing).
  Future<Result<SavedChecklist>> loadChecklist({
    required String bookingId,
    required ChecklistKind kind,
    required ChecklistSide side,
  });

  Future<Result<Booking>> confirmPickup({
    required String bookingId,
    required String userId,
    required BookingActor actor,
  });

  Future<Result<Booking>> startReturn({
    required String bookingId,
    required String userId,
    required BookingActor actor,
  });

  Future<Result<Booking>> confirmReturn({
    required String bookingId,
    required String userId,
    required BookingActor actor,
  });

  Future<Result<Booking>> markNoIssue({
    required String bookingId,
    required String userId,
  });

  Future<Result<Booking>> acknowledgeNoIssue({
    required String bookingId,
    required String userId,
  });

  Future<Result<Booking>> submitClaim({
    required String bookingId,
    required String userId,
    required int amount,
    required String reason,
    required List<String> evidenceUrls,
  });

  Future<Result<Booking>> respondToClaim({
    required String bookingId,
    required String userId,
    required ClaimResponse response,
  });

  Future<Result<Booking>> reviseClaim({
    required String bookingId,
    required String userId,
    required int amount,
    required String reason,
    required List<String> evidenceUrls,
  });

  Future<Result<Booking>> refundCaution({
    required String bookingId,
    required String userId,
  });

  /// The owner waives the late fee ([waived]), reduces it to [reducedFee], or
  /// restores the calculated fee (both null/false). Only while the booking is
  /// returning; every settlement path then uses the stored adjustment.
  Future<Result<Booking>> adjustLateFee({
    required String bookingId,
    required String userId,
    bool waived = false,
    int? reducedFee,
  });
}
