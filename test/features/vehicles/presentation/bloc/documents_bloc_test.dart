import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/entities/document_photo.dart';
import 'package:veloce/core/domain/entities/vehicle_document.dart';
import 'package:veloce/core/domain/enums/document_kind.dart';
import 'package:veloce/core/domain/enums/vehicle_status.dart';
import 'package:veloce/features/vehicles/domain/entities/document_input.dart';
import 'package:veloce/features/vehicles/domain/usecases/recompute_docs_valid_until.dart';
import 'package:veloce/features/vehicles/domain/usecases/set_status.dart';
import 'package:veloce/features/vehicles/domain/usecases/upsert_document.dart';
import 'package:veloce/features/vehicles/domain/usecases/verify_document.dart';
import 'package:veloce/features/vehicles/presentation/bloc/documents_bloc.dart';

import '../../domain/builders.dart';

VehicleDocument _doc(DocumentKind kind, DateTime expiry) => VehicleDocument(
  kind: kind,
  vehicleId: 'car-1',
  number: 'N-1',
  expiry: expiry,
  photoUrl: 'https://files.test/old.jpg',
  verified: true,
);

void main() {
  final clock = FixedClock(DateTime(2026, 11, 14));
  final expiredInsurance = _doc(DocumentKind.insurance, DateTime(2026, 11, 1));
  final medical = _doc(DocumentKind.medical, DateTime(2027, 9, 1));
  final pausedCar = aVehicle(docsValidUntil: DateTime(2026, 11, 1));

  FakeVehicleRepository repository() => FakeVehicleRepository()
    ..vehicles['car-1'] = pausedCar
    ..documents['car-1'] = [expiredInsurance, medical];

  DocumentsBloc buildBloc(FakeVehicleRepository repository) {
    return DocumentsBloc(
      vehicles: repository,
      upsertDocument: UpsertDocument(
        repository,
        FakeMediaStorage(),
        VerifyDocument(FakeVerificationProvider()),
        const RecomputeDocsValidUntil(),
        clock,
      ),
      setStatus: SetStatus(repository, clock),
      clock: clock,
    );
  }

  DocumentInput input({String plate = 'RAB 123 A'}) => DocumentInput(
    kind: DocumentKind.insurance,
    number: 'N-2',
    plate: plate,
    expiry: DateTime(2027, 6, 1),
    photo: DocumentPhoto(bytes: Uint8List(1), extension: 'jpg'),
  );

  late FakeVehicleRepository fake;

  group('DocumentsBloc loading', () {
    blocTest<DocumentsBloc, DocumentsState>(
      'paused car with expired insurance loads as paused by expiry',
      build: () => buildBloc(repository()),
      act: (bloc) => bloc.add(const DocumentsStarted('car-1')),
      verify: (bloc) {
        final state = bloc.state as DocumentsLoaded;
        expect(state.expired, {DocumentKind.insurance});
        expect(state.pausedByExpiry, isTrue);
        expect(state.canResume, isFalse);
      },
    );

    blocTest<DocumentsBloc, DocumentsState>(
      'a published car with lapsed papers is paused when opened',
      build: () {
        fake = FakeVehicleRepository()
          ..vehicles['car-1'] = aVehicle(
            status: VehicleStatus.published,
            docsValidUntil: DateTime(2026, 11, 1),
          )
          ..documents['car-1'] = [expiredInsurance, medical];
        return buildBloc(fake);
      },
      act: (bloc) => bloc.add(const DocumentsStarted('car-1')),
      verify: (bloc) {
        final state = bloc.state as DocumentsLoaded;
        expect(fake.statuses['car-1'], VehicleStatus.paused);
        expect(state.vehicle.status, VehicleStatus.paused);
        expect(state.pausedByExpiry, isTrue);
      },
    );

    blocTest<DocumentsBloc, DocumentsState>(
      'unknown car emits only loading',
      build: () => buildBloc(FakeVehicleRepository()),
      act: (bloc) => bloc.add(const DocumentsStarted('missing')),
      expect: () => [const DocumentsLoading()],
    );
  });

  group('DocumentsBloc saving', () {
    setUp(() => fake = repository());

    blocTest<DocumentsBloc, DocumentsState>(
      'replacing the insurance writes the document and shows a success notice',
      build: () => buildBloc(fake),
      act: (bloc) async {
        bloc.add(const DocumentsStarted('car-1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(DocumentSubmitted(input()));
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        final state = bloc.state as DocumentsLoaded;
        expect(state.busy, DocumentsBusy.none);
        expect(state.notice?.isError, isFalse);
        expect(fake.upserted.single.kind, DocumentKind.insurance);
        expect(fake.statuses['car-1'], VehicleStatus.paused);
      },
    );

    blocTest<DocumentsBloc, DocumentsState>(
      'wrong plate shows an error notice and keeps the documents',
      build: () => buildBloc(fake),
      act: (bloc) async {
        bloc.add(const DocumentsStarted('car-1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(DocumentSubmitted(input(plate: 'RAZ 999 Z')));
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        final state = bloc.state as DocumentsLoaded;
        expect(state.notice?.isError, isTrue);
        expect(state.busy, DocumentsBusy.none);
        expect(state.documents, [expiredInsurance, medical]);
      },
    );
  });

  group('DocumentsBloc resume', () {
    blocTest<DocumentsBloc, DocumentsState>(
      'resume with valid documents publishes the car',
      build: () {
        final fake = FakeVehicleRepository()
          ..vehicles['car-1'] = aVehicle(docsValidUntil: DateTime(2027, 9, 1))
          ..documents['car-1'] = [
            _doc(DocumentKind.insurance, DateTime(2027, 10, 1)),
            medical,
          ];
        return buildBloc(fake);
      },
      act: (bloc) async {
        bloc.add(const DocumentsStarted('car-1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const DocumentsResumeRequested());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        final state = bloc.state as DocumentsLoaded;
        expect(state.vehicle.status, VehicleStatus.published);
        expect(state.notice?.isError, isFalse);
      },
    );

    blocTest<DocumentsBloc, DocumentsState>(
      'resume with an expired paper shows the SetStatus error',
      build: () => buildBloc(repository()),
      act: (bloc) async {
        bloc.add(const DocumentsStarted('car-1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const DocumentsResumeRequested());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        final state = bloc.state as DocumentsLoaded;
        expect(state.vehicle.status, VehicleStatus.paused);
        expect(state.notice?.isError, isTrue);
      },
    );
  });
}
