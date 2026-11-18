import 'package:veloce/core/error/result.dart';

import '../../../../core/domain/entities/booking.dart';
import '../../../../core/domain/entities/checklist_entry.dart';
import '../../../../core/domain/entities/checklist_media.dart';
import '../../../../core/domain/enums/booking_actor.dart';
import '../../../../core/domain/enums/checklist_kind.dart';
import '../../../../core/domain/enums/checklist_side.dart';

abstract interface class HandoverRepository {
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
}
