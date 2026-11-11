import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:veloce/core/theme/app_theme.dart';
import 'package:veloce/features/profile/presentation/bloc/settings_cubit.dart';
import 'package:veloce/features/profile/presentation/pages/settings_page.dart';

class _MockSettingsCubit extends MockCubit<SettingsState>
    implements SettingsCubit {}

void main() {
  late _MockSettingsCubit cubit;

  setUp(() {
    cubit = _MockSettingsCubit();
    when(() => cubit.state).thenReturn(
      const SettingsState(
        themeMode: ThemeMode.system,
        notificationsEnabled: true,
      ),
    );
    when(() => cubit.selectThemeMode(any())).thenAnswer((_) async {});
    when(() => cubit.setNotificationsEnabled(enabled: any(named: 'enabled')))
        .thenAnswer((_) async {});
  });

  setUpAll(() => registerFallbackValue(ThemeMode.system));

  Future<void> pumpView(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: BlocProvider<SettingsCubit>.value(
        value: cubit,
        child: const SettingsView(),
      ),
    ),
  );

  testWidgets('choosing a theme calls the cubit', (tester) async {
    await pumpView(tester);

    await tester.tap(find.text('Dark'));
    await tester.pump();

    verify(() => cubit.selectThemeMode(ThemeMode.dark)).called(1);
  });

  testWidgets('the notifications switch calls the cubit', (tester) async {
    await pumpView(tester);

    await tester.tap(find.byType(Switch));
    await tester.pump();

    verify(() => cubit.setNotificationsEnabled(enabled: false)).called(1);
  });
}
