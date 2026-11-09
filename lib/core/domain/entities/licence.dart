import 'package:equatable/equatable.dart';

/// A renter's driving licence (private).
class Licence extends Equatable {
  const Licence({
    required this.userId,
    required this.number,
    required this.expiry,
    required this.photoUrl,
    required this.active,
  });

  final String userId;
  final String number;
  final DateTime expiry;
  final String photoUrl;
  final bool active;

  Licence copyWith({
    String? userId,
    String? number,
    DateTime? expiry,
    String? photoUrl,
    bool? active,
  }) {
    return Licence(
      userId: userId ?? this.userId,
      number: number ?? this.number,
      expiry: expiry ?? this.expiry,
      photoUrl: photoUrl ?? this.photoUrl,
      active: active ?? this.active,
    );
  }

  @override
  List<Object?> get props => [userId, number, expiry, photoUrl, active];
}
