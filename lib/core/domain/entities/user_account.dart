import 'package:equatable/equatable.dart';

import '../enums/user_role.dart';

/// Public profile of a person. Doc id is the Firebase Auth uid; contact details live in [Contact].
class UserAccount extends Equatable {
  const UserAccount({
    required this.id,
    required this.role,
    required this.name,
    required this.photoUrl,
    required this.verified,
    required this.ratingAvg,
    required this.ratingCount,
    required this.completedCount,
    required this.createdAt,
  });

  final String id;
  final UserRole role;
  final String name;
  final String? photoUrl;
  final bool verified;
  final double ratingAvg;
  final int ratingCount;
  final int completedCount;
  final DateTime createdAt;

  UserAccount copyWith({
    String? id,
    UserRole? role,
    String? name,
    String? photoUrl,
    bool? verified,
    double? ratingAvg,
    int? ratingCount,
    int? completedCount,
    DateTime? createdAt,
  }) {
    return UserAccount(
      id: id ?? this.id,
      role: role ?? this.role,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      verified: verified ?? this.verified,
      ratingAvg: ratingAvg ?? this.ratingAvg,
      ratingCount: ratingCount ?? this.ratingCount,
      completedCount: completedCount ?? this.completedCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    role,
    name,
    photoUrl,
    verified,
    ratingAvg,
    ratingCount,
    completedCount,
    createdAt,
  ];
}
