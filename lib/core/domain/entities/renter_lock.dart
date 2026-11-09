import 'package:equatable/equatable.dart';

/// Marks a renter as committed to one approved booking. Doc id is the renter id.
class RenterLock extends Equatable {
  const RenterLock({
    required this.renterId,
    required this.bookingId,
    required this.createdAt,
  });

  final String renterId;
  final String bookingId;
  final DateTime createdAt;

  RenterLock copyWith({
    String? renterId,
    String? bookingId,
    DateTime? createdAt,
  }) {
    return RenterLock(
      renterId: renterId ?? this.renterId,
      bookingId: bookingId ?? this.bookingId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [renterId, bookingId, createdAt];
}
