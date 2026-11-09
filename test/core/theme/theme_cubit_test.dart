import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veloce/core/data/services/preferences_service.dart';
import 'package:veloce/core/theme/theme_cubit.dart';

Future<PreferencesService> _preferences(Map<String, Object> initial) async {
  SharedPreferences.setMockInitialValues(initial);
  return PreferencesService(await SharedPreferences.getInstance());
}

void main() {
  test('starts from the saved theme mode', () async {
    final cubit = ThemeCubit(await _preferences({'theme_mode': 'dark'}));
    expect(cubit.state, ThemeMode.dark);
    await cubit.close();
  });

  test('defaults to system when nothing or garbage is stored', () async {
    final cubit = ThemeCubit(await _preferences({'theme_mode': 'sepia'}));
    expect(cubit.state, ThemeMode.system);
    await cubit.close();
  });

  blocTest<ThemeCubit, ThemeMode>(
    'select emits the new mode and persists it',
    build: () => ThemeCubit(PreferencesService(_FakePrefsHolder.instance)),
    setUp: () async {
      SharedPreferences.setMockInitialValues({});
      _FakePrefsHolder.instance = await SharedPreferences.getInstance();
    },
    act: (cubit) => cubit.select(ThemeMode.light),
    expect: () => [ThemeMode.light],
    verify: (_) =>
        expect(_FakePrefsHolder.instance.getString('theme_mode'), 'light'),
  );

  blocTest<ThemeCubit, ThemeMode>(
    'selecting the current mode emits nothing',
    build: () => ThemeCubit(PreferencesService(_FakePrefsHolder.instance)),
    setUp: () async {
      SharedPreferences.setMockInitialValues({});
      _FakePrefsHolder.instance = await SharedPreferences.getInstance();
    },
    act: (cubit) => cubit.select(ThemeMode.system),
    expect: () => <ThemeMode>[],
  );
}

class _FakePrefsHolder {
  static late SharedPreferences instance;
}
