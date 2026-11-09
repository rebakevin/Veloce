import 'package:equatable/equatable.dart';

import '../enums/checklist_kind.dart';
import '../enums/checklist_side.dart';
import '../enums/media_type.dart';

/// A photo or video attached to a checklist.
class ChecklistMedia extends Equatable {
  const ChecklistMedia({
    required this.id,
    required this.bookingId,
    required this.kind,
    required this.side,
    required this.mediaType,
    required this.url,
    required this.at,
  });

  final String id;
  final String bookingId;
  final ChecklistKind kind;
  final ChecklistSide side;
  final MediaType mediaType;
  final String url;
  final DateTime at;

  ChecklistMedia copyWith({
    String? id,
    String? bookingId,
    ChecklistKind? kind,
    ChecklistSide? side,
    MediaType? mediaType,
    String? url,
    DateTime? at,
  }) {
    return ChecklistMedia(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      kind: kind ?? this.kind,
      side: side ?? this.side,
      mediaType: mediaType ?? this.mediaType,
      url: url ?? this.url,
      at: at ?? this.at,
    );
  }

  @override
  List<Object?> get props => [id, bookingId, kind, side, mediaType, url, at];
}
