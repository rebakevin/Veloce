import 'package:equatable/equatable.dart';

import '../enums/checklist_side.dart';

/// Phone and email of one party, unlocked for the other after payment. Doc id is the side.
class BookingContact extends Equatable {
  const BookingContact({
    required this.side,
    required this.bookingId,
    required this.phone,
    required this.email,
    required this.meetingPoint,
  });

  final ChecklistSide side;
  final String bookingId;
  final String phone;
  final String email;
  final String? meetingPoint;

  BookingContact copyWith({
    ChecklistSide? side,
    String? bookingId,
    String? phone,
    String? email,
    String? meetingPoint,
  }) {
    return BookingContact(
      side: side ?? this.side,
      bookingId: bookingId ?? this.bookingId,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      meetingPoint: meetingPoint ?? this.meetingPoint,
    );
  }

  @override
  List<Object?> get props => [side, bookingId, phone, email, meetingPoint];
}
