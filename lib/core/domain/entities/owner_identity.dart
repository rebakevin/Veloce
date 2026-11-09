import 'package:equatable/equatable.dart';

/// An owner's National ID (private).
class OwnerIdentity extends Equatable {
  const OwnerIdentity({
    required this.userId,
    required this.nationalIdNumber,
    required this.photoUrl,
  });

  final String userId;
  final String nationalIdNumber;
  final String photoUrl;

  OwnerIdentity copyWith({
    String? userId,
    String? nationalIdNumber,
    String? photoUrl,
  }) {
    return OwnerIdentity(
      userId: userId ?? this.userId,
      nationalIdNumber: nationalIdNumber ?? this.nationalIdNumber,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  @override
  List<Object?> get props => [userId, nationalIdNumber, photoUrl];
}
