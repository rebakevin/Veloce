import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/services/preferences_service.dart';

/// App theme mode, restored from and saved to [PreferencesService].
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._preferences) : super(_preferences.themeMode);

  final PreferencesService _preferences;

  Future<void> select(ThemeMode mode) async {
    if (mode == state) return;
    emit(mode);
    await _preferences.setThemeMode(mode);
  }
}
