import 'package:bloc/bloc.dart';

import 'package:veloce/core/data/services/preferences_service.dart';
import 'package:veloce/core/domain/enums/vehicle_type.dart';

import '../../domain/entities/search_query.dart';
import 'search_state.dart';

/// Owns the area, dates and home type chip. Restores and saves the two
/// preferences listed in TECHNICAL.md §9.
class SearchCubit extends Cubit<SearchState> {
  SearchCubit({required PreferencesService preferences})
    : _preferences = preferences,
      super(
        SearchState(
          area: _readArea(preferences.lastSearchArea),
          typeChip: _readType(preferences.lastTypeChip),
        ),
      );

  final PreferencesService _preferences;

  SearchQuery? get query => state.query;

  void areaChanged(String? area) {
    emit(
      area == null
          ? state.copyWith(clearArea: true)
          : state.copyWith(area: area),
    );
  }

  void datesChanged(DateTime? start, DateTime? end) {
    emit(state.copyWith(start: start, end: end));
  }

  void typeChipChanged(VehicleType? type) {
    emit(
      type == null
          ? state.copyWith(clearTypeChip: true)
          : state.copyWith(typeChip: type),
    );
  }

  /// Persists the form. Called when a search starts, not on every keystroke.
  Future<void> savePreferences() async {
    final area = state.area;
    if (area != null) await _preferences.setLastSearchArea(area);
    final type = state.typeChip;
    await _preferences.setLastTypeChip(type?.key ?? '');
  }

  static String? _readArea(String? value) =>
      value == null || value.isEmpty ? null : value;

  static VehicleType? _readType(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return VehicleType.fromKey(value);
    } on ArgumentError {
      return null;
    }
  }
}
