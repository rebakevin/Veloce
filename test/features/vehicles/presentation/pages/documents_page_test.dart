import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:veloce/core/domain/entities/vehicle_document.dart';
import 'package:veloce/core/domain/enums/document_kind.dart';
import 'package:veloce/core/theme/app_theme.dart';
import 'package:veloce/core/widgets/app_messenger.dart';
import 'package:veloce/features/vehicles/presentation/bloc/documents_bloc.dart';
import 'package:veloce/features/vehicles/presentation/pages/documents_page.dart';

import '../../domain/builders.dart';

class _MockDocumentsBloc extends MockBloc<DocumentsEvent, DocumentsState>
    implements DocumentsBloc {}

VehicleDocument _doc(DocumentKind kind, DateTime expiry) => VehicleDocument(
  kind: kind,
  vehicleId: 'car-1',
  number: 'N-1',
  expiry: expiry,
  photoUrl: 'https://files.test/a.jpg',
  verified: true,
);

void main() {
  setUp(() {
    if (!GetIt.I.isRegistered<AppMessenger>()) {
      GetIt.I.registerSingleton(AppMessenger());
    }
  });

  tearDown(GetIt.I.reset);

  Future<void> pump(WidgetTester tester, DocumentsState state) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 2400);
    addTearDown(tester.view.reset);
    final bloc = _MockDocumentsBloc();
    whenListen(bloc, const Stream<DocumentsState>.empty(), initialState: state);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider<DocumentsBloc>.value(
          value: bloc,
          child: const DocumentsPage(vehicleId: 'car-1'),
        ),
      ),
    );
  }

  testWidgets('paused car with expired insurance shows banner and Replace', (
    tester,
  ) async {
    await pump(
      tester,
      DocumentsLoaded(
        vehicle: aVehicle(),
        documents: [
          _doc(DocumentKind.insurance, DateTime(2026, 11, 1)),
          _doc(DocumentKind.medical, DateTime(2027, 9, 1)),
        ],
        expired: const {DocumentKind.insurance},
      ),
    );

    expect(find.text('Paused by expiry'), findsOneWidget);
    expect(find.text('Replace insurance'), findsOneWidget);
    expect(find.text('Add yellow paper'), findsOneWidget);
    expect(find.text('Resume listing'), findsNothing);
  });

  testWidgets('valid papers on a paused car offer Resume', (tester) async {
    await pump(
      tester,
      DocumentsLoaded(
        vehicle: aVehicle(),
        documents: [
          _doc(DocumentKind.insurance, DateTime(2027, 10, 1)),
          _doc(DocumentKind.medical, DateTime(2027, 9, 1)),
        ],
        expired: const {},
      ),
    );

    expect(find.text('Paused by expiry'), findsNothing);
    expect(find.text('Resume listing'), findsOneWidget);
  });
}
