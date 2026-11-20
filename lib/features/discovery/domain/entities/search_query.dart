import 'package:equatable/equatable.dart';

import 'package:veloce/core/domain/enums/vehicle_type.dart';

/// What the renter wants to find: an area, a rental date range and an optional
/// home type chip. The area is `null` for "Anywhere in Kigali".
class SearchQuery extends Equatable {
  const SearchQuery({
    required this.start,
    required this.end,
    this.area,
    this.typeChip,
  });

  final String? area;
  final DateTime start;
  final DateTime end;
  final VehicleType? typeChip;

  int get days => end.difference(start).inDays;

  SearchQuery copyWith({
    String? area,
    DateTime? start,
    DateTime? end,
    VehicleType? typeChip,
    bool clearArea = false,
    bool clearTypeChip = false,
  }) {
    return SearchQuery(
      area: clearArea ? null : (area ?? this.area),
      start: start ?? this.start,
      end: end ?? this.end,
      typeChip: clearTypeChip ? null : (typeChip ?? this.typeChip),
    );
  }

  @override
  List<Object?> get props => [area, start, end, typeChip];
}
