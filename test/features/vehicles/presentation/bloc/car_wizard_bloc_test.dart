import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/enums/document_kind.dart';
import 'package:veloce/features/vehicles/domain/entities/wizard_step.dart';
import 'package:veloce/features/vehicles/domain/rules/wizard_step_rules.dart';
import 'package:veloce/features/vehicles/domain/usecases/load_vehicle_draft.dart';
import 'package:veloce/features/vehicles/domain/usecases/publish_vehicle.dart';
import 'package:veloce/features/vehicles/domain/usecases/update_vehicle.dart';
import 'package:veloce/features/vehicles/domain/usecases/verify_document.dart';
import 'package:veloce/features/vehicles/presentation/bloc/car_wizard_bloc.dart';

import '../../domain/builders.dart';

CarWizardBloc buildBloc({
  FakeVehicleRepository? repository,
  FakeVerificationProvider? verification,
}) {
  final vehicles = repository ?? FakeVehicleRepository();
  const session = FakeAuthSession('owner-1');
  final storage = FakeMediaStorage();
  return CarWizardBloc(
    verifyDocument: VerifyDocument(verification ?? FakeVerificationProvider()),
    publishVehicle: PublishVehicle(
      vehicles,
      storage,
      session,
      FixedClock(DateTime(2026, 11, 14)),
    ),
    updateVehicle: UpdateVehicle(vehicles, storage, session),
    loadVehicleDraft: LoadVehicleDraft(vehicles, session),
  );
}

void main() {
  group('CarWizardBloc next', () {
    blocTest<CarWizardBloc, CarWizardState>(
      'next with an invalid step shows the errors and stays',
      build: () => buildBloc(),
      act: (bloc) => bloc.add(const WizardNextPressed()),
      expect: () => [
        isA<CarWizardState>()
            .having((s) => s.step, 'step', WizardStep.media)
            .having((s) => s.errors.keys, 'errors', [WizardField.photos]),
      ],
    );

    blocTest<CarWizardBloc, CarWizardState>(
      'next with a valid step moves to the next step',
      build: () => buildBloc(),
      seed: () => CarWizardState(draft: aWizardDraft()),
      act: (bloc) => bloc.add(const WizardNextPressed()),
      expect: () => [
        CarWizardState(step: WizardStep.details, draft: aWizardDraft()),
      ],
    );

    blocTest<CarWizardBloc, CarWizardState>(
      'next on the last step does nothing',
      build: () => buildBloc(),
      seed: () =>
          CarWizardState(step: WizardStep.review, draft: aWizardDraft()),
      act: (bloc) => bloc.add(const WizardNextPressed()),
      expect: () => <CarWizardState>[],
    );
  });

  group('CarWizardBloc back', () {
    blocTest<CarWizardBloc, CarWizardState>(
      'back moves to the previous step',
      build: () => buildBloc(),
      seed: () =>
          CarWizardState(step: WizardStep.details, draft: aWizardDraft()),
      act: (bloc) => bloc.add(const WizardBackPressed()),
      expect: () => [CarWizardState(draft: aWizardDraft())],
    );

    blocTest<CarWizardBloc, CarWizardState>(
      'back on the first step does nothing',
      build: () => buildBloc(),
      act: (bloc) => bloc.add(const WizardBackPressed()),
      expect: () => <CarWizardState>[],
    );
  });

  group('CarWizardBloc draft changes', () {
    blocTest<CarWizardBloc, CarWizardState>(
      'fixing the draft after an error clears the error',
      build: () => buildBloc(),
      seed: () => const CarWizardState(
        errors: {WizardField.photos: 'Add 3 to 6 photos.'},
      ),
      act: (bloc) => bloc.add(WizardDraftChanged(aWizardDraft())),
      expect: () => [CarWizardState(draft: aWizardDraft())],
    );

    blocTest<CarWizardBloc, CarWizardState>(
      'a change before any error does not validate',
      build: () => buildBloc(),
      act: (bloc) => bloc.add(WizardDraftChanged(aWizardDraft())),
      expect: () => [CarWizardState(draft: aWizardDraft())],
    );
  });

  group('CarWizardBloc documents', () {
    final unverified = aWizardDraft().copyWith(
      documents: {
        DocumentKind.insurance: aDraftDocument().copyWith(verified: false),
      },
    );

    blocTest<CarWizardBloc, CarWizardState>(
      'a successful check marks the document verified',
      build: () => buildBloc(),
      seed: () => CarWizardState(step: WizardStep.documents, draft: unverified),
      act: (bloc) =>
          bloc.add(const WizardDocumentVerifyRequested(DocumentKind.insurance)),
      expect: () => [
        isA<CarWizardState>().having(
          (s) => s.verifying,
          'verifying',
          DocumentKind.insurance,
        ),
        isA<CarWizardState>()
            .having((s) => s.verifying, 'verifying', isNull)
            .having(
              (s) => s.draft.documents[DocumentKind.insurance]!.verified,
              'verified',
              true,
            ),
      ],
    );

    blocTest<CarWizardBloc, CarWizardState>(
      'a failed check keeps it unverified and shows the message',
      build: () =>
          buildBloc(verification: FakeVerificationProvider(succeeds: false)),
      seed: () => CarWizardState(step: WizardStep.documents, draft: unverified),
      act: (bloc) =>
          bloc.add(const WizardDocumentVerifyRequested(DocumentKind.insurance)),
      expect: () => [
        isA<CarWizardState>().having(
          (s) => s.verifying,
          'verifying',
          DocumentKind.insurance,
        ),
        isA<CarWizardState>()
            .having(
              (s) => s.errors.containsKey(WizardField.documentInsurance),
              'error',
              true,
            )
            .having(
              (s) => s.draft.documents[DocumentKind.insurance]!.verified,
              'verified',
              false,
            ),
      ],
    );
  });

  group('CarWizardBloc publish', () {
    blocTest<CarWizardBloc, CarWizardState>(
      'publish on the last step saves the car and reports its id',
      build: () => buildBloc(),
      seed: () =>
          CarWizardState(step: WizardStep.review, draft: aPublishableDraft()),
      act: (bloc) => bloc.add(const WizardPublishPressed()),
      expect: () => [
        isA<CarWizardState>().having(
          (s) => s.submission,
          'submission',
          WizardSubmission.publishing,
        ),
        isA<CarWizardState>()
            .having(
              (s) => s.submission,
              'submission',
              WizardSubmission.published,
            )
            .having((s) => s.publishedId, 'id', 'car-new'),
      ],
    );

    blocTest<CarWizardBloc, CarWizardState>(
      'a failed save reports the failure and allows another try',
      build: () =>
          buildBloc(repository: FakeVehicleRepository(publishFails: true)),
      seed: () =>
          CarWizardState(step: WizardStep.review, draft: aPublishableDraft()),
      act: (bloc) => bloc.add(const WizardPublishPressed()),
      expect: () => [
        isA<CarWizardState>().having(
          (s) => s.submission,
          'submission',
          WizardSubmission.publishing,
        ),
        isA<CarWizardState>()
            .having((s) => s.submission, 'submission', WizardSubmission.failure)
            .having((s) => s.message, 'message', isNotNull),
      ],
    );

    blocTest<CarWizardBloc, CarWizardState>(
      'publish before the last step does nothing',
      build: () => buildBloc(),
      seed: () => CarWizardState(draft: aPublishableDraft()),
      act: (bloc) => bloc.add(const WizardPublishPressed()),
      expect: () => <CarWizardState>[],
    );
  });
}
