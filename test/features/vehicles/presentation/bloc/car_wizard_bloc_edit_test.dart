import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/entities/vehicle.dart';
import 'package:veloce/core/domain/entities/vehicle_photo.dart';
import 'package:veloce/core/domain/enums/vehicle_status.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/vehicles/domain/entities/wizard_step.dart';
import 'package:veloce/features/vehicles/domain/usecases/load_vehicle_draft.dart';
import 'package:veloce/features/vehicles/domain/usecases/publish_vehicle.dart';
import 'package:veloce/features/vehicles/domain/usecases/update_vehicle.dart';
import 'package:veloce/features/vehicles/domain/usecases/verify_document.dart';
import 'package:veloce/features/vehicles/presentation/bloc/car_wizard_bloc.dart';

import '../../domain/builders.dart';

class _UpdateFailsRepository extends FakeVehicleRepository {
  @override
  Future<Result<void>> update(
    Vehicle vehicle,
    List<VehiclePhoto> photos,
  ) async => const Result.failure(NetworkFailure());
}

VehiclePhoto aPhoto(int order) => VehiclePhoto(
  id: 'p$order',
  vehicleId: 'car-1',
  url: 'https://files.test/old$order.jpg',
  order: order,
  isPrimary: order == 1,
);

FakeVehicleRepository seeded(FakeVehicleRepository repository) {
  repository.vehicles['car-1'] = aVehicle(status: VehicleStatus.published);
  repository.photos['car-1'] = [aPhoto(2), aPhoto(0), aPhoto(1)];
  return repository;
}

CarWizardBloc buildBloc(FakeVehicleRepository repository) {
  const session = FakeAuthSession('owner-1');
  final storage = FakeMediaStorage();
  return CarWizardBloc(
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
}

Future<CarWizardBloc> atReview(
  FakeVehicleRepository repository, {
  int? dailyPrice,
}) async {
  final bloc = buildBloc(repository)..add(const WizardEditStarted('car-1'));
  await bloc.stream.firstWhere((s) => s.submission == WizardSubmission.idle);
  if (dailyPrice != null) {
    bloc.add(
      WizardDraftChanged(bloc.state.draft.copyWith(dailyPrice: dailyPrice)),
    );
  }
  for (var i = 0; i < 5; i++) {
    bloc.add(const WizardNextPressed());
  }
  await bloc.stream.firstWhere((s) => s.step == WizardStep.review);
  return bloc;
}

void main() {
  group('CarWizardBloc edit mode', () {
    blocTest<CarWizardBloc, CarWizardState>(
      'loading a car fills the draft with its fields and photos',
      build: () => buildBloc(seeded(FakeVehicleRepository())),
      act: (bloc) => bloc.add(const WizardEditStarted('car-1')),
      expect: () => [
        isA<CarWizardState>().having(
          (s) => s.submission,
          'submission',
          WizardSubmission.loading,
        ),
        isA<CarWizardState>()
            .having((s) => s.submission, 'submission', WizardSubmission.idle)
            .having((s) => s.draft.vehicleId, 'vehicleId', 'car-1')
            .having((s) => s.draft.make, 'make', 'Toyota')
            .having((s) => s.draft.dailyPrice, 'price', 50000)
            .having((s) => s.draft.keptPhotos.map((p) => p.order), 'order', [
              0,
              1,
              2,
            ])
            .having((s) => s.draft.primaryIndex, 'primary', 1),
      ],
    );

    blocTest<CarWizardBloc, CarWizardState>(
      'loading a missing car reports the failure and can be retried',
      build: () => buildBloc(FakeVehicleRepository()),
      act: (bloc) => bloc.add(const WizardEditStarted('nope')),
      expect: () => [
        isA<CarWizardState>().having(
          (s) => s.submission,
          'submission',
          WizardSubmission.loading,
        ),
        isA<CarWizardState>()
            .having(
              (s) => s.submission,
              'submission',
              WizardSubmission.loadFailure,
            )
            .having((s) => s.isBusy, 'busy', false),
      ],
    );

    blocTest<CarWizardBloc, CarWizardState>(
      'the documents step is skipped when editing',
      build: () => buildBloc(seeded(FakeVehicleRepository())),
      act: (bloc) async {
        bloc.add(const WizardEditStarted('car-1'));
        await bloc.stream.firstWhere(
          (s) => s.submission == WizardSubmission.idle,
        );
        for (var i = 0; i < 5; i++) {
          bloc.add(const WizardNextPressed());
        }
      },
      skip: 2,
      expect: () => [
        isA<CarWizardState>().having((s) => s.step, 'step', WizardStep.details),
        isA<CarWizardState>().having((s) => s.step, 'step', WizardStep.specs),
        isA<CarWizardState>().having((s) => s.step, 'step', WizardStep.pricing),
        isA<CarWizardState>().having((s) => s.step, 'step', WizardStep.rules),
        isA<CarWizardState>().having((s) => s.step, 'step', WizardStep.review),
      ],
    );

    test('saving a changed price updates the car', () async {
      final repository = seeded(FakeVehicleRepository());
      final bloc = await atReview(repository, dailyPrice: 65000);

      bloc.add(const WizardPublishPressed());
      final done = await bloc.stream.firstWhere(
        (s) => s.submission == WizardSubmission.published,
      );

      expect(done.publishedId, 'car-1');
      expect(repository.vehicles['car-1']!.dailyPrice, 65000);
      await bloc.close();
    });

    test('a failed save reports the failure and allows a retry', () async {
      final bloc = await atReview(seeded(_UpdateFailsRepository()));

      bloc.add(const WizardPublishPressed());
      final failed = await bloc.stream.firstWhere(
        (s) => s.submission == WizardSubmission.failure,
      );

      expect(failed.message, isNotNull);
      expect(failed.isBusy, false);
      await bloc.close();
    });
  });
}
