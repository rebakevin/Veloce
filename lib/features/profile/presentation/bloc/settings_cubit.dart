import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'package:veloce/core/data/services/preferences_service.dart';
import 'package:veloce/core/theme/theme_cubit.dart';

class SettingsState extends Equatable {
  const SettingsState({
    required this.themeMode,
    required this.notificationsEnabled,
  });

  final ThemeMode themeMode;
  final bool notificationsEnabled;

  SettingsState copyWith({ThemeMode? themeMode, bool? notificationsEnabled}) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  @override
  List<Object?> get props => [themeMode, notificationsEnabled];
}

/// Settings screen state. Theme changes go through the app-wide [ThemeCubit]
/// (which persists them), and this cubit mirrors it so both stay in sync.
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({
    required PreferencesService preferences,
    required ThemeCubit themeCubit,
  }) : _preferences = preferences,
       _themeCubit = themeCubit,
       super(
         SettingsState(
           themeMode: themeCubit.state,
           notificationsEnabled: preferences.notificationsEnabled,
         ),
       ) {
    _themeSubscription = _themeCubit.stream.listen(
      (mode) => emit(state.copyWith(themeMode: mode)),
    );
  }

  final PreferencesService _preferences;
  final ThemeCubit _themeCubit;
  late final StreamSubscription<ThemeMode> _themeSubscription;

  Future<void> selectThemeMode(ThemeMode mode) => _themeCubit.select(mode);

  Future<void> setNotificationsEnabled({required bool enabled}) async {
    if (enabled == state.notificationsEnabled) return;
    emit(state.copyWith(notificationsEnabled: enabled));
    await _preferences.setNotificationsEnabled(enabled: enabled);
  }

  @override
  Future<void> close() async {
    await _themeSubscription.cancel();
    return super.close();
  }
}
