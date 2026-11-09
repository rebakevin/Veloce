import 'package:equatable/equatable.dart';

import '../enums/checklist_kind.dart';
import '../enums/checklist_side.dart';

/// One ticked pickup or return checklist item.
class ChecklistEntry extends Equatable {
  const ChecklistEntry({
    required this.id,
    required this.bookingId,
    required this.kind,
    required this.side,
    required this.item,
    required this.ticked,
    required this.at,
  });

  final String id;
  final String bookingId;
  final ChecklistKind kind;
  final ChecklistSide side;
  final String item;
  final bool ticked;
  final DateTime at;

  ChecklistEntry copyWith({
    String? id,
    String? bookingId,
    ChecklistKind? kind,
    ChecklistSide? side,
    String? item,
    bool? ticked,
    DateTime? at,
  }) {
    return ChecklistEntry(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      kind: kind ?? this.kind,
      side: side ?? this.side,
      item: item ?? this.item,
      ticked: ticked ?? this.ticked,
      at: at ?? this.at,
    );
  }

  @override
  List<Object?> get props => [id, bookingId, kind, side, item, ticked, at];
}
