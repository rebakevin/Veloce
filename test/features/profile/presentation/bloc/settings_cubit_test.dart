import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/data/services/preferences_service.dart';
import 'package:veloce/core/theme/theme_cubit.dart';
import 'package:veloce/features/profile/presentation/bloc/settings_cubit.dart';

class _MockPreferences extends Mock implements PreferencesService {}

void main() {
  late _MockPreferences preferences;
  late ThemeCubit themeCubit;

  setUpAll(() => registerFallbackValue(ThemeMode.system));

  setUp(() {
    preferences = _MockPreferences();
    when(() => preferences.themeMode).thenReturn(ThemeMode.system);
    when(() => preferences.notificationsEnabled).thenReturn(true);
    when(() => preferences.setThemeMode(any())).thenAnswer((_) async {});
    when(
      () => preferences.setNotificationsEnabled(enabled: any(named: 'enabled')),
    ).thenAnswer((_) async {});
    themeCubit = ThemeCubit(preferences);
  });

  SettingsCubit build() =>
      SettingsCubit(preferences: preferences, themeCubit: themeCubit);

  test('starts from the stored preferences', () {
    final cubit = build();
    expect(
      cubit.state,
      const SettingsState(
        themeMode: ThemeMode.system,
        notificationsEnabled: true,
      ),
    );
  });

  blocTest<SettingsCubit, SettingsState>(
    'theme is persisted through ThemeCubit and mirrored',
    build: build,
    act: (cubit) => cubit.selectThemeMode(ThemeMode.dark),
    expect: () => [
      const SettingsState(
        themeMode: ThemeMode.dark,
        notificationsEnabled: true,
      ),
    ],
    verify: (_) {
      expect(themeCubit.state, ThemeMode.dark);
      verify(() => preferences.setThemeMode(ThemeMode.dark)).called(1);
    },
  );

  blocTest<SettingsCubit, SettingsState>(
    'follows a theme change made elsewhere',
    build: build,
    act: (cubit) => themeCubit.select(ThemeMode.light),
    expect: () => [
      const SettingsState(
        themeMode: ThemeMode.light,
        notificationsEnabled: true,
      ),
    ],
  );

  blocTest<SettingsCubit, SettingsState>(
    'notifications toggle is persisted',
    build: build,
    act: (cubit) => cubit.setNotificationsEnabled(enabled: false),
    expect: () => [
      const SettingsState(
        themeMode: ThemeMode.system,
        notificationsEnabled: false,
      ),
    ],
    verify: (_) =>
        verify(() => preferences.setNotificationsEnabled(enabled: false))
            .called(1),
  );
}
