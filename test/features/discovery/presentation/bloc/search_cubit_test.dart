import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:veloce/core/data/services/preferences_service.dart';
import 'package:veloce/core/domain/enums/vehicle_type.dart';
import 'package:veloce/features/discovery/presentation/bloc/search_cubit.dart';

class _MockPreferences extends Mock implements PreferencesService {}

void main() {
  late _MockPreferences preferences;

  setUp(() {
    preferences = _MockPreferences();
    when(() => preferences.lastSearchArea).thenReturn('Kacyiru');
    when(() => preferences.lastTypeChip).thenReturn('suv');
    when(() => preferences.setLastSearchArea(any())).thenAnswer((_) async {});
    when(() => preferences.setLastTypeChip(any())).thenAnswer((_) async {});
  });

  test('restores area and type from preferences', () {
    final cubit = SearchCubit(preferences: preferences);
    expect(cubit.state.area, 'Kacyiru');
    expect(cubit.state.typeChip, VehicleType.suv);
    cubit.close();
  });

  test('saves area and type when a search starts', () async {
    final cubit = SearchCubit(preferences: preferences);
    cubit
      ..areaChanged('Nyarutarama')
      ..datesChanged(DateTime(2026, 11, 20), DateTime(2026, 11, 23))
      ..typeChipChanged(VehicleType.sedan);
    await cubit.savePreferences();
    verify(() => preferences.setLastSearchArea('Nyarutarama')).called(1);
    verify(() => preferences.setLastTypeChip('sedan')).called(1);
    expect(cubit.query?.days, 3);
    await cubit.close();
  });

  test('falls back to no type for an unknown stored value', () {
    when(() => preferences.lastTypeChip).thenReturn('spaceship');
    final cubit = SearchCubit(preferences: preferences);
    expect(cubit.state.typeChip, isNull);
    cubit.close();
  });
}
