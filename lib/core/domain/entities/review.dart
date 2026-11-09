import 'package:equatable/equatable.dart';

import '../enums/subject_type.dart';

/// A star rating and comment about a user or a vehicle.
class Review extends Equatable {
  const Review({
    required this.id,
    required this.bookingId,
    required this.authorId,
    required this.subjectType,
    required this.subjectId,
    required this.stars,
    required this.comment,
    required this.createdAt,
    required this.editedAt,
  });

  final String id;
  final String bookingId;
  final String authorId;
  final SubjectType subjectType;
  final String subjectId;
  final int stars;
  final String comment;
  final DateTime createdAt;
  final DateTime? editedAt;

  Review copyWith({
    String? id,
    String? bookingId,
    String? authorId,
    SubjectType? subjectType,
    String? subjectId,
    int? stars,
    String? comment,
    DateTime? createdAt,
    DateTime? editedAt,
  }) {
    return Review(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      authorId: authorId ?? this.authorId,
      subjectType: subjectType ?? this.subjectType,
      subjectId: subjectId ?? this.subjectId,
      stars: stars ?? this.stars,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    bookingId,
    authorId,
    subjectType,
    subjectId,
    stars,
    comment,
    createdAt,
    editedAt,
  ];
}
