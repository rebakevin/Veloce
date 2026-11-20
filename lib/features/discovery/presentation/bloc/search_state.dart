import 'package:equatable/equatable.dart';

import 'package:veloce/core/domain/enums/vehicle_type.dart';

import '../../domain/entities/search_query.dart';

/// The home/search form. Dates stay empty until the renter picks them.
class SearchState extends Equatable {
  const SearchState({this.area, this.start, this.end, this.typeChip});

  final String? area;
  final DateTime? start;
  final DateTime? end;
  final VehicleType? typeChip;

  SearchQuery? get query {
    final start = this.start;
    final end = this.end;
    if (start == null || end == null) return null;
    return SearchQuery(area: area, start: start, end: end, typeChip: typeChip);
  }

  SearchState copyWith({
    String? area,
    DateTime? start,
    DateTime? end,
    VehicleType? typeChip,
    bool clearArea = false,
    bool clearTypeChip = false,
  }) {
    return SearchState(
      area: clearArea ? null : (area ?? this.area),
      start: start ?? this.start,
      end: end ?? this.end,
      typeChip: clearTypeChip ? null : (typeChip ?? this.typeChip),
    );
  }

  @override
  List<Object?> get props => [area, start, end, typeChip];
}
