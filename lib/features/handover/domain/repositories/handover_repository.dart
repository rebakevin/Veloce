import 'package:veloce/core/error/result.dart';

import '../../../../core/domain/entities/booking.dart';
import '../../../../core/domain/entities/caution_claim.dart';
import '../../../../core/domain/entities/checklist_entry.dart';
import '../../../../core/domain/entities/checklist_media.dart';
import '../../../../core/domain/enums/booking_actor.dart';
import '../../../../core/domain/enums/checklist_kind.dart';
import '../../../../core/domain/enums/checklist_side.dart';
import '../../../../core/domain/enums/claim_response.dart';

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
}
