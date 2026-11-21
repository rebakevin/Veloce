import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/enums/vehicle_status.dart';
import 'package:veloce/core/theme/app_theme.dart';
import 'package:veloce/features/vehicles/presentation/widgets/vehicle_card.dart';

import '../../domain/builders.dart';

void main() {
  Future<List<String>> pump(
    WidgetTester tester, {
    VehicleStatus status = VehicleStatus.published,
    bool docsExpired = false,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 2400);
    addTearDown(tester.view.reset);
    final taps = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: VehicleCard(
            vehicle: aVehicle(status: status),
            docsExpired: docsExpired,
            onOpen: () => taps.add('open'),
            onEdit: () => taps.add('edit'),
            onAvailability: () => taps.add('availability'),
            onDocuments: () => taps.add('documents'),
            onToggleStatus: () => taps.add('toggle'),
            onRemove: () => taps.add('remove'),
          ),
        ),
      ),
    );
    return taps;
  }

  testWidgets('a published car offers Pause and a Documents action', (
    tester,
  ) async {
    final taps = await pump(tester);

    expect(find.text('Pause'), findsOneWidget);
    await tester.tap(find.text('Documents'));
    await tester.tap(find.text('Pause'));

    expect(taps, ['documents', 'toggle']);
  });

  testWidgets('a paused car offers Resume', (tester) async {
    await pump(tester, status: VehicleStatus.paused);

    expect(find.text('Resume'), findsOneWidget);
  });

  testWidgets('expired papers show a paused-by-expiry chip and Fix documents', (
    tester,
  ) async {
    await pump(tester, docsExpired: true);

    expect(find.text('Paused: documents expired'), findsOneWidget);
    expect(find.text('Fix documents'), findsOneWidget);
  });

  testWidgets('a car without dates says it is hidden from search', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('No dates set: hidden from search'), findsOneWidget);
  });
}
