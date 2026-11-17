import 'package:equatable/equatable.dart';

import 'package:veloce/core/domain/entities/booking.dart';
import 'package:veloce/core/domain/entities/user_account.dart';
import 'package:veloce/core/domain/entities/vehicle.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/domain/enums/user_role.dart';

/// A booking with the data its screens need: the status users should see, the
/// car, and both parties. [effectiveStatus] resolves lazy expiry and the renter
/// lock without waiting for a write.
class BookingView extends Equatable {
  const BookingView({
    required this.booking,
    required this.effectiveStatus,
    required this.vehicle,
    required this.renter,
    required this.owner,
  });

  final Booking booking;
  final BookingStatus effectiveStatus;
  final Vehicle vehicle;
  final UserAccount renter;
  final UserAccount owner;

  UserAccount counterpartFor(UserRole role) =>
      role == UserRole.renter ? owner : renter;

  bool get isOpen =>
      effectiveStatus == BookingStatus.pending ||
      effectiveStatus == BookingStatus.approved;

  bool get isActive => switch (effectiveStatus) {
    BookingStatus.confirmed ||
    BookingStatus.active ||
    BookingStatus.returning ||
    BookingStatus.review => true,
    _ => false,
  };

  bool get isPast => !isOpen && !isActive;

  /// Contact documents are readable only after payment (TECHNICAL.md §5.4).
  bool get isContactUnlocked => switch (effectiveStatus) {
    BookingStatus.confirmed ||
    BookingStatus.active ||
    BookingStatus.returning ||
    BookingStatus.review => true,
    _ => false,
  };

  @override
  List<Object?> get props => [booking, effectiveStatus, vehicle, renter, owner];
}
