import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/theme/app_theme.dart';
import 'package:veloce/features/vehicles/domain/usecases/load_vehicle_draft.dart';
import 'package:veloce/features/vehicles/domain/usecases/publish_vehicle.dart';
import 'package:veloce/features/vehicles/domain/usecases/update_vehicle.dart';
import 'package:veloce/features/vehicles/domain/usecases/verify_document.dart';
import 'package:veloce/features/vehicles/presentation/bloc/car_wizard_bloc.dart';
import 'package:veloce/features/vehicles/presentation/pages/car_wizard_page.dart';

import '../../domain/builders.dart';

void main() {
  testWidgets('the photos step shows an inline error and blocks Next', (
    tester,
  ) async {
    final repository = FakeVehicleRepository();
    const session = FakeAuthSession('owner-1');
    final storage = FakeMediaStorage();
    final bloc = CarWizardBloc(
      verifyDocument: VerifyDocument(FakeVerificationProvider()),
      publishVehicle: PublishVehicle(
        repository,
        storage,
        session,
        FixedClock(DateTime(2026, 11, 14)),
      ),
      updateVehicle: UpdateVehicle(repository, storage, session),
      loadVehicleDraft: LoadVehicleDraft(repository, session),
    );
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider.value(value: bloc, child: const CarWizardPage()),
      ),
    );
    expect(find.text('Add 3 to 6 photos.'), findsNothing);

    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(find.text('Add 3 to 6 photos.'), findsOneWidget);
    expect(find.text('Step 1 of 7 · Media'), findsOneWidget);
    expect(find.text('Vehicle details'), findsNothing);
  });
}
