import 'package:equatable/equatable.dart';

/// What anyone may see of a user. Contact details are not part of it and must
/// never be added: they live in the private `Contact` document.
class PublicProfile extends Equatable {
  const PublicProfile({
    required this.userId,
    required this.name,
    required this.photoUrl,
    required this.ratingAvg,
    required this.ratingCount,
    required this.completedCount,
  });

  final String userId;
  final String name;
  final String? photoUrl;
  final double ratingAvg;
  final int ratingCount;
  final int completedCount;

  /// Shown as a "first-time" badge: no completed rental yet.
  bool get isFirstTime => completedCount == 0;

  @override
  List<Object?> get props => [
    userId,
    name,
    photoUrl,
    ratingAvg,
    ratingCount,
    completedCount,
  ];
}
